理解了！以下是将 MQ 相关功能按标准开发步骤单独列出的详细说明：

## 📋 MQ 开发标准步骤（RabbitMQ + Spring Boot）

### 第 1 步：添加依赖

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

### 第 2 步：配置文件

```yaml
# application.yml
spring:
  rabbitmq:
    host: 172.23.165.246    # RabbitMQ服务器地址
    port: 5672              # 端口
    username: guest         # 用户名
    password: guest         # 密码
    virtual-host: /         # 虚拟主机
    publisher-confirm-type: correlated  # 发布确认
    publisher-returns: true             # 返回确认
    template:
      mandatory: true       # 消息路由失败处理
```

### 第 3 步：创建消息实体类（DTO）

```java
// 1. 审计日志消息
@Data
@AllArgsConstructor
@NoArgsConstructor
public class AuditLogMessage {
    private String operation;      // 操作类型
    private String operator;       // 操作人
    private String details;        // 操作详情
    private LocalDateTime timestamp;
}

// 2. 贷款审批通知消息
@Data
@AllArgsConstructor
@NoArgsConstructor
public class LoanApprovedNotification {
    private Long loanId;           // 贷款ID
    private String customerName;   // 客户姓名
    private String phoneNumber;    // 手机号
    private String idCard;         // 身份证
    private String email;          // 邮箱
    private BigDecimal amount;     // 贷款金额
}

// 3. 逾期提醒消息
@Data
@AllArgsConstructor
@NoArgsConstructor
public class OverdueReminderMessage {
    private Long scheduleId;       // 还款计划ID
    private Long loanId;           // 贷款ID
    private String customerName;   // 客户姓名
    private String email;          // 邮箱
    private String phoneNumber;    // 手机号
    private BigDecimal totalAmount;// 应还金额
    private LocalDate dueDate;     // 应还日期
}
```

### 第 4 步：配置队列、交换机、绑定关系

```java
@Configuration
public class RabbitMQConfig {
    
    // ================== 审计日志队列 ==================
    public static final String AUDIT_LOG_QUEUE = "audit.log.queue";
    public static final String AUDIT_LOG_EXCHANGE = "audit.log.exchange";
    public static final String AUDIT_LOG_ROUTING_KEY = "audit.log";
    
    @Bean
    public Queue auditLogQueue() {
        return QueueBuilder.durable(AUDIT_LOG_QUEUE)  // 持久化队列
                .build();
    }
    
    @Bean
    public TopicExchange auditLogExchange() {
        return new TopicExchange(AUDIT_LOG_EXCHANGE);
    }
    
    @Bean
    public Binding auditLogBinding() {
        return BindingBuilder.bind(auditLogQueue())
                .to(auditLogExchange())
                .with(AUDIT_LOG_ROUTING_KEY);
    }
    
    // ================== 贷款通知队列 ==================
    public static final String NOTIFICATION_QUEUE = "notification.queue";
    public static final String NOTIFICATION_EXCHANGE = "notification.exchange";
    public static final String NOTIFICATION_ROUTING_KEY = "loan.approved";
    
    @Bean
    public Queue notificationQueue() {
        return QueueBuilder.durable(NOTIFICATION_QUEUE)
                .withArgument("x-message-ttl", 300000)  // 消息TTL：5分钟
                .build();
    }
    
    @Bean
    public TopicExchange notificationExchange() {
        return new TopicExchange(NOTIFICATION_EXCHANGE);
    }
    
    @Bean
    public Binding notificationBinding() {
        return BindingBuilder.bind(notificationQueue())
                .to(notificationExchange())
                .with(NOTIFICATION_ROUTING_KEY);
    }
    
    // ================== 逾期通知队列 ==================
    public static final String OVERDUE_NOTIFICATION_QUEUE = "overdue.notification.queue";
    public static final String OVERDUE_NOTIFICATION_EXCHANGE = "overdue.notification.exchange";
    public static final String OVERDUE_ROUTING_KEY = "loan.overdue";
    
    @Bean
    public Queue overdueNotificationQueue() {
        return QueueBuilder.durable(OVERDUE_NOTIFICATION_QUEUE).build();
    }
    
    @Bean
    public TopicExchange overdueNotificationExchange() {
        return new TopicExchange(OVERDUE_NOTIFICATION_EXCHANGE);
    }
    
    @Bean
    public Binding overdueNotificationBinding() {
        return BindingBuilder.bind(overdueNotificationQueue())
                .to(overdueNotificationExchange())
                .with(OVERDUE_ROUTING_KEY);
    }
    
    // ================== JSON消息转换器 ==================
    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
```

### 第 5 步：创建消息生产者（发送消息）

```java
@Component
@Slf4j
public class MessageProducer {
    
    @Autowired
    private RabbitTemplate rabbitTemplate;
    
    // 1. 发送审计日志
    public void sendAuditLog(AuditLogMessage message) {
        try {
            rabbitTemplate.convertAndSend(
                RabbitMQConfig.AUDIT_LOG_EXCHANGE,
                RabbitMQConfig.AUDIT_LOG_ROUTING_KEY,
                message
            );
            log.info("✅ 审计日志发送成功: {}", message.getOperation());
        } catch (Exception e) {
            log.error("❌ 发送审计日志失败", e);
        }
    }
    
    // 2. 发送贷款审批通知
    public void sendLoanApprovalNotification(LoanApprovedNotification notification) {
        try {
            // 设置消息属性
            MessageProperties properties = new MessageProperties();
            properties.setMessageId(UUID.randomUUID().toString());
            properties.setTimestamp(new Date());
            properties.setDeliveryMode(MessageDeliveryMode.PERSISTENT);  // 持久化
            
            Message message = rabbitTemplate.getMessageConverter()
                .toMessage(notification, properties);
            
            rabbitTemplate.send(
                RabbitMQConfig.NOTIFICATION_EXCHANGE,
                RabbitMQConfig.NOTIFICATION_ROUTING_KEY,
                message
            );
            log.info("✅ 贷款审批通知发送成功，贷款ID: {}", notification.getLoanId());
        } catch (Exception e) {
            log.error("❌ 发送贷款审批通知失败", e);
        }
    }
    
    // 3. 发送逾期提醒
    public void sendOverdueReminder(OverdueReminderMessage message) {
        rabbitTemplate.convertAndSend(
            RabbitMQConfig.OVERDUE_NOTIFICATION_EXCHANGE,
            RabbitMQConfig.OVERDUE_ROUTING_KEY,
            message
        );
        log.info("✅ 逾期提醒发送成功，贷款ID: {}", message.getLoanId());
    }
}
```

### 第 6 步：创建消息消费者（接收消息）

```java
// 1. 审计日志消费者
@Component
@Slf4j
public class AuditLogConsumer {
    
    @Autowired
    private AuditLogMapper auditLogMapper;  // MyBatis Mapper
    
    @RabbitListener(queues = RabbitMQConfig.AUDIT_LOG_QUEUE)
    @Transactional
    public void processAuditLog(AuditLogMessage message) {
        log.info("📝 收到审计日志: {}", message.getOperation());
        
        try {
            // 保存到数据库
            AuditLog entity = new AuditLog();
            BeanUtils.copyProperties(message, entity);
            auditLogMapper.insert(entity);
            
            log.info("✅ 审计日志已入库: {}", entity.getId());
        } catch (Exception e) {
            log.error("❌ 处理审计日志失败", e);
            // 可在此处添加重试逻辑或发送到死信队列
        }
    }
}

// 2. 贷款通知消费者
@Component
@Slf4j
public class NotificationConsumer {
    
    @Autowired
    private EmailService emailService;
    
    @Autowired
    private RedisTemplate<String, String> redisTemplate;
    
    @RabbitListener(queues = RabbitMQConfig.NOTIFICATION_QUEUE)
    @Transactional
    public void processLoanApproval(LoanApprovedNotification notification) {
        log.info("📬 收到贷款审批通知: {}", notification.getLoanId());
        
        // 幂等性检查
        String key = "loan:notification:sent:" + notification.getLoanId();
        if (Boolean.TRUE.equals(redisTemplate.hasKey(key))) {
            log.warn("🚫 通知已发送，跳过处理: {}", notification.getLoanId());
            return;
        }
        
        try {
            // 发送邮件
            String subject = "【银行贷款系统】您的贷款申请已批准";
            String content = String.format(
                "尊敬的 %s：<br>您的贷款申请(编号: %s)已批准，金额: ¥%s",
                notification.getCustomerName(),
                notification.getLoanId(),
                notification.getAmount()
            );
            
            emailService.send(notification.getEmail(), subject, content);
            
            // 标记已发送
            redisTemplate.opsForValue().set(key, "sent", Duration.ofDays(7));
            
            log.info("✅ 邮件发送成功: {}", notification.getEmail());
        } catch (Exception e) {
            log.error("❌ 处理贷款通知失败", e);
            throw new AmqpRejectAndDontRequeueException("处理失败，进入死信队列");
        }
    }
}
```

### 第 7 步：业务层调用生产者

```java
@Service
public class LoanServiceImpl implements LoanService {
    
    @Autowired
    private MessageProducer messageProducer;
    
    @Override
    @Transactional
    public void approveLoan(Long loanId, boolean approved) {
        // 1. 业务逻辑处理
        Loan loan = loanMapper.selectById(loanId);
        loan.setStatus(approved ? "APPROVED" : "REJECTED");
        loanMapper.updateById(loan);
        
        // 2. 发送审计日志
        AuditLogMessage auditLog = new AuditLogMessage(
            "APPROVE_LOAN",
            SecurityUtil.getCurrentUsername(),
            "审批贷款ID: " + loanId
        );
        messageProducer.sendAuditLog(auditLog);
        
        // 3. 如果批准，发送通知
        if (approved) {
            LoanApprovedNotification notification = new LoanApprovedNotification(
                loanId,
                loan.getCustomerName(),
                loan.getPhoneNumber(),
                loan.getIdCard(),
                loan.getEmail(),
                loan.getAmount()
            );
            messageProducer.sendLoanApprovalNotification(notification);
        }
    }
}
```

### 第 8 步：配置消费者确认机制

```java
@Configuration
public class RabbitMQListenerConfig {
    
    @Bean
    public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory(
            ConnectionFactory connectionFactory) {
        SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
        factory.setConnectionFactory(connectionFactory);
        factory.setAcknowledgeMode(AcknowledgeMode.MANUAL);  // 手动确认
        factory.setPrefetchCount(10);  // 每次预取消息数量
        factory.setConcurrentConsumers(3);  // 并发消费者数量
        factory.setMaxConcurrentConsumers(10);  // 最大并发消费者
        return factory;
    }
}
```

### 第 9 步：手动确认消息（消费者端）

```java
@Component
public class ManualAckConsumer {
    
    @RabbitListener(queues = "your.queue")
    public void processMessage(Message message, Channel channel) throws IOException {
        try {
            // 处理业务逻辑
            doBusiness(message);
            
            // 手动确认消息
            channel.basicAck(
                message.getMessageProperties().getDeliveryTag(),
                false  // 不批量确认
            );
        } catch (Exception e) {
            // 处理失败，拒绝消息
            channel.basicNack(
                message.getMessageProperties().getDeliveryTag(),
                false,  // 不批量拒绝
                true    // 重新入队
            );
        }
    }
}
```

### 第 10 步：配置死信队列（可选）

```java
@Configuration
public class DLQConfig {
    
    // 死信交换机
    @Bean
    public DirectExchange dlxExchange() {
        return new DirectExchange("dlx.exchange");
    }
    
    // 死信队列
    @Bean
    public Queue dlxQueue() {
        return QueueBuilder.durable("dlx.queue").build();
    }
    
    // 绑定
    @Bean
    public Binding dlxBinding() {
        return BindingBuilder.bind(dlxQueue())
                .to(dlxExchange())
                .with("dlx.routing.key");
    }
    
    // 配置业务队列时指定死信队列
    @Bean
    public Queue businessQueue() {
        return QueueBuilder.durable("business.queue")
                .withArgument("x-dead-letter-exchange", "dlx.exchange")
                .withArgument("x-dead-letter-routing-key", "dlx.routing.key")
                .withArgument("x-message-ttl", 60000)  // 1分钟后进入死信
                .build();
    }
}
```

## 📊 开发注意事项

### 1. **消息可靠性**
- 生产者：开启 `publisher-confirm` 和 `publisher-returns`
- 消息：设置为 `PERSISTENT`（持久化）
- 消费者：手动确认模式

### 2. **幂等性处理**
- 使用 Redis 记录已处理的消息ID
- 消息中添加唯一标识
- 消费者端做重复判断

### 3. **错误处理**
- 配置重试机制（Spring Retry）
- 设置死信队列（DLQ）
- 记录错误日志

### 4. **性能优化**
- 合理设置 `prefetchCount`
- 根据业务量调整并发消费者数量
- 使用连接池

### 5. **监控**
- 配置 RabbitMQ 管理界面
- Spring Boot Actuator 监控
- 关键指标：队列长度、消费速率、错误率

## 📝 常见问题解决

### Q: 消息发送失败怎么办？
```java
// 实现 RabbitTemplate.ConfirmCallback
rabbitTemplate.setConfirmCallback((correlationData, ack, cause) -> {
    if (ack) {
        log.info("消息发送成功: {}", correlationData.getId());
    } else {
        log.error("消息发送失败: {}", cause);
        // 重发或记录到数据库
    }
});
```

### Q: 消费者处理失败怎么处理？
```java
// 配置重试机制
@Bean
public SimpleRabbitListenerContainerFactory rabbitListenerContainerFactory() {
    SimpleRabbitListenerContainerFactory factory = new SimpleRabbitListenerContainerFactory();
    factory.setConnectionFactory(connectionFactory);
    
    // 设置重试策略
    RetryTemplate retryTemplate = new RetryTemplate();
    FixedBackOffPolicy backOffPolicy = new FixedBackOffPolicy();
    backOffPolicy.setBackOffPeriod(3000);  // 3秒重试
    retryTemplate.setBackOffPolicy(backOffPolicy);
    retryTemplate.setRetryPolicy(new SimpleRetryPolicy(3));  // 重试3次
    
    factory.setRetryTemplate(retryTemplate);
    return factory;
}
```

这样按照标准步骤开发，可以确保 MQ 功能的可靠性、可维护性和可扩展性。
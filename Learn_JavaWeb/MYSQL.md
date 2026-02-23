明白了！以下是 MySQL 相关开发的标准操作步骤（基于 MyBatis-Plus）：

## 📋 MySQL + MyBatis-Plus 开发标准步骤

### 第 1 步：添加依赖

```xml
<!-- pom.xml -->
<dependencies>
    <!-- MySQL驱动 -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>
    
    <!-- MyBatis-Plus -->
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
        <version>3.5.7</version>
    </dependency>
    
    <!-- 数据库连接池（可选，Spring Boot自带Hikari） -->
    <dependency>
        <groupId>com.zaxxer</groupId>
        <artifactId>HikariCP</artifactId>
    </dependency>
</dependencies>
```

### 第 2 步：配置文件

```yaml
# application.yml
spring:
  datasource:
    # 主数据源配置
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/bank_loan?useUnicode=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai&useSSL=false
    username: root
    password: 123456
    
    # Hikari连接池配置
    hikari:
      connection-timeout: 30000      # 连接超时时间（毫秒）
      maximum-pool-size: 20          # 最大连接数
      minimum-idle: 5                # 最小空闲连接数
      idle-timeout: 600000           # 空闲连接超时时间
      max-lifetime: 1800000          # 连接最大生命周期
      connection-test-query: SELECT 1 # 连接测试查询

# MyBatis-Plus配置
mybatis-plus:
  configuration:
    map-underscore-to-camel-case: true  # 开启驼峰命名转换
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl  # 控制台SQL日志
    cache-enabled: true                  # 开启二级缓存
  global-config:
    db-config:
      id-type: auto                     # ID生成策略：数据库自增
      logic-delete-field: is_deleted    # 逻辑删除字段名
      logic-delete-value: 1             # 逻辑删除值
      logic-not-delete-value: 0         # 逻辑未删除值
  mapper-locations: classpath*:/mapper/**/*.xml  # Mapper XML位置
  type-aliases-package: com.yali.bankloansystem.entity  # 实体类包路径
```

### 第 3 步：创建实体类（Entity）

```java
package com.yali.bankloansystem.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

// 贷款申请表
@Data
@TableName("loans")  // 指定表名
public class Loan {
    
    // 主键策略：数据库自增
    @TableId(value = "id", type = IdType.AUTO)
    private Long id;
    
    // 普通字段
    private String customerName;      // 客户姓名
    
    // 字段映射：如果数据库字段与Java字段不一致
    @TableField("id_card")
    private String idCard;            // 身份证号
    
    // 敏感字段：不参与查询（可加脱敏注解）
    private String phoneNumber;       // 手机号
    private String email;             // 邮箱
    
    // 数值类型
    private BigDecimal amount;        // 贷款金额
    
    // 状态字段
    private String status;            // 状态：PENDING, APPROVED, REJECTED
    
    // 时间字段
    @TableField(fill = FieldFill.INSERT)  // 插入时自动填充
    private LocalDateTime applyTime;  // 申请时间
    
    // 逻辑删除
    @TableLogic
    @TableField("is_deleted")
    private Integer deleted;          // 逻辑删除标志
    
    // 乐观锁版本号
    @Version
    private Integer version;          // 版本号
    
    // 忽略字段：不参与数据库操作
    @TableField(exist = false)
    private String tempField;
}
```

### 第 4 步：创建Mapper接口

```java
package com.yali.bankloansystem.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.yali.bankloansystem.entity.Loan;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import java.util.List;

@Mapper  // 必须添加此注解
public interface LoanMapper extends BaseMapper<Loan> {
    
    // ========== 1. 继承BaseMapper，获得基础CRUD ==========
    // 已有方法：insert, deleteById, updateById, selectById, selectList等
    
    // ========== 2. 自定义查询方法（注解方式） ==========
    
    // 根据状态查询
    @Select("SELECT * FROM loans WHERE status = #{status} ORDER BY apply_time DESC")
    List<Loan> selectByStatus(@Param("status") String status);
    
    // 根据客户姓名模糊查询
    @Select("SELECT * FROM loans WHERE customer_name LIKE CONCAT('%', #{name}, '%')")
    List<Loan> selectByCustomerName(@Param("name") String name);
    
    // 统计某个客户的贷款总额
    @Select("SELECT COALESCE(SUM(amount), 0) FROM loans WHERE customer_name = #{customerName}")
    BigDecimal sumAmountByCustomer(@Param("customerName") String customerName);
    
    // ========== 3. 复杂查询（XML方式） ==========
    // 在XML中定义，这里只声明方法
    List<Loan> selectComplexQuery(@Param("minAmount") BigDecimal minAmount,
                                 @Param("maxAmount") BigDecimal maxAmount,
                                 @Param("statusList") List<String> statusList);
}
```

### 第 5 步：创建Mapper XML文件（复杂SQL）

```xml
<!-- src/main/resources/mapper/LoanMapper.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.yali.bankloansystem.mapper.LoanMapper">
    
    <!-- 复杂查询示例 -->
    <select id="selectComplexQuery" resultType="com.yali.bankloansystem.entity.Loan">
        SELECT *
        FROM loans
        WHERE is_deleted = 0
        <if test="minAmount != null">
            AND amount >= #{minAmount}
        </if>
        <if test="maxAmount != null">
            AND amount &lt;= #{maxAmount}
        </if>
        <if test="statusList != null and statusList.size() > 0">
            AND status IN
            <foreach collection="statusList" item="status" open="(" separator="," close=")">
                #{status}
            </foreach>
        </if>
        ORDER BY apply_time DESC
        LIMIT 100
    </select>
    
    <!-- 联表查询示例（如果需要） -->
    <select id="selectLoanWithUser" resultMap="loanWithUserMap">
        SELECT l.*, u.username, u.role
        FROM loans l
        LEFT JOIN users u ON l.applicant_id = u.id
        WHERE l.id = #{loanId}
    </select>
    
    <resultMap id="loanWithUserMap" type="com.yali.bankloansystem.entity.Loan">
        <id property="id" column="id"/>
        <result property="customerName" column="customer_name"/>
        <!-- 其他字段映射 -->
        <association property="applicant" javaType="com.yali.bankloansystem.entity.User">
            <id property="id" column="applicant_id"/>
            <result property="username" column="username"/>
            <result property="role" column="role"/>
        </association>
    </resultMap>
    
    <!-- 批量插入 -->
    <insert id="batchInsert" parameterType="java.util.List">
        INSERT INTO loans (customer_name, id_card, amount, status, apply_time)
        VALUES
        <foreach collection="list" item="item" separator=",">
            (#{item.customerName}, #{item.idCard}, #{item.amount}, 
             #{item.status}, #{item.applyTime})
        </foreach>
    </insert>
</mapper>
```

### 第 6 步：创建Service接口

```java
package com.yali.bankloansystem.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.yali.bankloansystem.entity.Loan;
import java.math.BigDecimal;
import java.util.List;

// 继承IService获得增强的CRUD功能
public interface LoanService extends IService<Loan> {
    
    // ========== 业务方法定义 ==========
    
    // 申请贷款
    Loan applyLoan(Loan loan);
    
    // 审批贷款
    void approveLoan(Long loanId, boolean approved);
    
    // 根据客户姓名查询
    List<Loan> getLoansByCustomerName(String customerName);
    
    // 统计贷款金额
    BigDecimal getTotalLoanAmount(String customerName);
    
    // 分页查询待审批贷款
    List<Loan> getPendingLoans(int page, int size);
}
```

### 第 7 步：创建Service实现类

```java
package com.yali.bankloansystem.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.yali.bankloansystem.entity.Loan;
import com.yali.bankloansystem.mapper.LoanMapper;
import com.yali.bankloansystem.service.LoanService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
public class LoanServiceImpl extends ServiceImpl<LoanMapper, Loan> implements LoanService {
    
    @Override
    @Transactional(rollbackFor = Exception.class)  // 事务管理
    public Loan applyLoan(Loan loan) {
        // 1. 数据校验
        if (loan.getAmount() == null || loan.getAmount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("贷款金额必须大于0");
        }
        
        // 2. 设置默认值
        loan.setStatus("PENDING");
        loan.setApplyTime(LocalDateTime.now());
        
        // 3. 保存到数据库
        boolean success = save(loan);  // 使用MyBatis-Plus的save方法
        
        if (!success) {
            throw new RuntimeException("保存贷款申请失败");
        }
        
        return loan;
    }
    
    @Override
    @Transactional
    public void approveLoan(Long loanId, boolean approved) {
        // 1. 查询贷款
        Loan loan = getById(loanId);
        if (loan == null) {
            throw new RuntimeException("贷款不存在");
        }
        
        // 2. 更新状态
        loan.setStatus(approved ? "APPROVED" : "REJECTED");
        
        // 3. 使用MyBatis-Plus的updateById
        boolean success = updateById(loan);
        
        if (!success) {
            throw new RuntimeException("更新贷款状态失败");
        }
    }
    
    @Override
    public List<Loan> getLoansByCustomerName(String customerName) {
        // 使用LambdaQueryWrapper构建查询条件
        LambdaQueryWrapper<Loan> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(Loan::getCustomerName, customerName)
                   .orderByDesc(Loan::getApplyTime);
        
        return list(queryWrapper);  // 使用MyBatis-Plus的list方法
    }
    
    @Override
    public BigDecimal getTotalLoanAmount(String customerName) {
        // 使用自定义的Mapper方法
        return baseMapper.sumAmountByCustomer(customerName);
    }
    
    @Override
    public List<Loan> getPendingLoans(int page, int size) {
        // 分页查询
        Page<Loan> pageParam = new Page<>(page, size);
        
        LambdaQueryWrapper<Loan> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(Loan::getStatus, "PENDING")
                   .orderByAsc(Loan::getApplyTime);
        
        IPage<Loan> result = page(pageParam, queryWrapper);
        
        return result.getRecords();
    }
    
    // ========== 其他常用操作示例 ==========
    
    // 批量更新状态
    @Transactional
    public void batchUpdateStatus(List<Long> loanIds, String status) {
        LambdaQueryWrapper<Loan> updateWrapper = new LambdaQueryWrapper<>();
        updateWrapper.in(Loan::getId, loanIds);
        
        Loan updateEntity = new Loan();
        updateEntity.setStatus(status);
        
        update(updateEntity, updateWrapper);
    }
    
    // 条件查询（多条件）
    public List<Loan> searchLoans(String customerName, BigDecimal minAmount, 
                                  BigDecimal maxAmount, String status) {
        LambdaQueryWrapper<Loan> queryWrapper = new LambdaQueryWrapper<>();
        
        if (customerName != null && !customerName.trim().isEmpty()) {
            queryWrapper.like(Loan::getCustomerName, customerName);
        }
        
        if (minAmount != null) {
            queryWrapper.ge(Loan::getAmount, minAmount);  // >=
        }
        
        if (maxAmount != null) {
            queryWrapper.le(Loan::getAmount, maxAmount);  // <=
        }
        
        if (status != null && !status.trim().isEmpty()) {
            queryWrapper.eq(Loan::getStatus, status);
        }
        
        queryWrapper.orderByDesc(Loan::getApplyTime);
        
        return list(queryWrapper);
    }
}
```

### 第 8 步：配置MyBatis-Plus插件

```java
package com.yali.bankloansystem.config;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.BlockAttackInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.OptimisticLockerInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class MyBatisPlusConfig {
    
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        
        // 1. 分页插件
        PaginationInnerInterceptor paginationInterceptor = new PaginationInnerInterceptor(DbType.MYSQL);
        paginationInterceptor.setMaxLimit(1000L);  // 单页最大记录数
        paginationInterceptor.setOverflow(true);   // 超过最大页数后回到第一页
        interceptor.addInnerInterceptor(paginationInterceptor);
        
        // 2. 乐观锁插件（@Version注解）
        interceptor.addInnerInterceptor(new OptimisticLockerInnerInterceptor());
        
        // 3. 防止全表更新与删除插件
        interceptor.addInnerInterceptor(new BlockAttackInnerInterceptor());
        
        return interceptor;
    }
    
    // 自动填充处理器
    @Bean
    public MetaObjectHandler metaObjectHandler() {
        return new MetaObjectHandler() {
            @Override
            public void insertFill(MetaObject metaObject) {
                this.strictInsertFill(metaObject, "applyTime", LocalDateTime.class, LocalDateTime.now());
                this.strictInsertFill(metaObject, "createTime", LocalDateTime.class, LocalDateTime.now());
                this.strictInsertFill(metaObject, "createBy", String.class, getCurrentUsername());
            }
            
            @Override
            public void updateFill(MetaObject metaObject) {
                this.strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, LocalDateTime.now());
                this.strictUpdateFill(metaObject, "updateBy", String.class, getCurrentUsername());
            }
            
            private String getCurrentUsername() {
                // 获取当前用户逻辑
                return "system";
            }
        };
    }
}
```

### 第 9 步：Controller层调用

```java
package com.yali.bankloansystem.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.yali.bankloansystem.entity.Loan;
import com.yali.bankloansystem.service.LoanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/loan")
public class LoanController {
    
    @Autowired
    private LoanService loanService;
    
    // 申请贷款
    @PostMapping("/apply")
    public Loan applyLoan(@RequestBody Loan loan) {
        return loanService.applyLoan(loan);
    }
    
    // 审批贷款
    @PutMapping("/approve/{id}")
    public void approveLoan(@PathVariable Long id, @RequestParam boolean approved) {
        loanService.approveLoan(id, approved);
    }
    
    // 查询贷款详情
    @GetMapping("/{id}")
    public Loan getLoan(@PathVariable Long id) {
        return loanService.getById(id);
    }
    
    // 分页查询
    @GetMapping("/page")
    public IPage<Loan> getLoansPage(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String customerName) {
        
        Page<Loan> pageParam = new Page<>(page, size);
        
        if (customerName != null && !customerName.trim().isEmpty()) {
            // 条件查询分页
            return loanService.lambdaQuery()
                    .like(Loan::getCustomerName, customerName)
                    .page(pageParam);
        }
        
        // 无条件分页
        return loanService.page(pageParam);
    }
    
    // 统计接口
    @GetMapping("/stats")
    public Object getLoanStats() {
        // 使用MyBatis-Plus的聚合查询
        long total = loanService.count();
        long pending = loanService.lambdaQuery()
                .eq(Loan::getStatus, "PENDING")
                .count();
        long approved = loanService.lambdaQuery()
                .eq(Loan::getStatus, "APPROVED")
                .count();
        
        return Map.of(
            "total", total,
            "pending", pending,
            "approved", approved
        );
    }
}
```

### 第 10 步：创建数据库表

```sql
-- 贷款表
CREATE TABLE `loans` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `customer_name` varchar(100) NOT NULL COMMENT '客户姓名',
  `id_card` varchar(18) NOT NULL COMMENT '身份证号',
  `phone_number` varchar(11) DEFAULT NULL COMMENT '手机号码',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `amount` decimal(15,2) NOT NULL COMMENT '贷款金额',
  `status` varchar(20) DEFAULT 'PENDING' COMMENT '状态：PENDING, APPROVED, REJECTED',
  `apply_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '申请时间',
  `applicant_id` bigint(20) DEFAULT NULL COMMENT '申请人ID',
  `product_code` varchar(50) DEFAULT NULL COMMENT '贷款产品代码',
  
  -- 审计字段
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  
  -- 逻辑删除
  `is_deleted` tinyint(1) DEFAULT '0' COMMENT '逻辑删除：0-未删除，1-已删除',
  
  -- 乐观锁
  `version` int(11) DEFAULT '0' COMMENT '版本号',
  
  PRIMARY KEY (`id`),
  KEY `idx_customer_name` (`customer_name`),
  KEY `idx_status` (`status`),
  KEY `idx_apply_time` (`apply_time`),
  KEY `idx_applicant_id` (`applicant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='贷款申请表';

-- 用户表
CREATE TABLE `users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL UNIQUE COMMENT '用户名',
  `password` varchar(255) NOT NULL COMMENT '密码',
  `role` varchar(20) DEFAULT 'CUSTOMER' COMMENT '角色：CUSTOMER, LOAN_OFFICER, ADMIN',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- 审计日志表
CREATE TABLE `audit_logs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `operation` varchar(100) NOT NULL COMMENT '操作类型',
  `operator` varchar(50) DEFAULT NULL COMMENT '操作人',
  `details` text COMMENT '操作详情',
  `timestamp` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_operation` (`operation`),
  KEY `idx_operator` (`operator`),
  KEY `idx_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审计日志表';
```

## 📊 开发规范

### 1. **命名规范**
- 表名：复数形式，小写字母，下划线分隔 `snake_case`
- 字段名：小写字母，下划线分隔 `snake_case`
- Java实体类：单数形式，驼峰命名 `CamelCase`
- Mapper接口：`XxxMapper.java`
- Service接口：`XxxService.java`
- Service实现：`XxxServiceImpl.java`

### 2. **事务管理规范**
```java
// 只读查询
@Transactional(readOnly = true)
public List<Loan> queryLoans() {
    // 查询操作
}

// 写操作
@Transactional(rollbackFor = Exception.class)
public void updateLoan(Loan loan) {
    // 更新操作
}

// 嵌套事务
@Transactional(propagation = Propagation.REQUIRED)
public void processLoan() {
    // 外层事务
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void auditLog() {
        // 独立事务
    }
}
```

### 3. **SQL编写规范**
```java
// ✅ 推荐：使用LambdaQueryWrapper
List<Loan> loans = loanService.lambdaQuery()
    .eq(Loan::getStatus, "PENDING")
    .ge(Loan::getAmount, new BigDecimal("10000"))
    .orderByDesc(Loan::getApplyTime)
    .list();

// ❌ 避免：硬编码SQL（除非复杂查询）
@Select("SELECT * FROM loans WHERE status = 'PENDING'")
List<Loan> findPendingLoans();
```

### 4. **分页规范**
```java
// 分页查询
Page<Loan> page = new Page<>(1, 10);
IPage<Loan> result = loanService.page(page, queryWrapper);

// 不查询总数（提高性能）
Page<Loan> page = new Page<>(1, 10, false);  // 第三个参数为false
```

### 5. **性能优化建议**
1. **索引优化**：为查询条件字段添加索引
2. **避免全表扫描**：使用合适的查询条件
3. **批量操作**：使用 `batchInsert`、`batchUpdate`
4. **连接池配置**：合理配置连接池参数
5. **SQL监控**：开启MyBatis日志，监控慢SQL

### 6. **安全注意事项**
1. **SQL注入防护**：使用MyBatis-Plus的Wrapper，不要拼接SQL
2. **数据脱敏**：敏感字段（身份证、手机号）在返回前端时脱敏
3. **权限控制**：Service层添加权限校验
4. **参数校验**：使用`@Valid`注解进行参数校验

这样按步骤开发，可以保证数据库操作的规范性、可维护性和性能优化。
# MyBatis-Plus 分页插件简单模板

## 1. **配置类**（必需）

```java
// MyBatisPlusConfig.java
@Configuration
public class MyBatisPlusConfig {
    @Bean
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        // 添加分页插件
        interceptor.addInnerInterceptor(new PaginationInnerInterceptor(DbType.MYSQL));
        return interceptor;
    }
}
```

## 2. **Service层使用**（最简）

```java
// UserService.java
@Service
public class UserService extends ServiceImpl<UserMapper, User> {
    
    // 方法1：基础分页
    public IPage<User> getPage(int page, int size) {
        Page<User> pageParam = new Page<>(page, size);
        return page(pageParam);
    }
    
    // 方法2：带条件分页
    public IPage<User> getPageByCondition(int page, int size, String name) {
        Page<User> pageParam = new Page<>(page, size);
        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        
        if (name != null && !name.isEmpty()) {
            wrapper.like(User::getName, name);  // 姓名模糊查询
        }
        wrapper.orderByDesc(User::getCreateTime);  // 按创建时间倒序
        
        return page(pageParam, wrapper);
    }
}
```

## 3. **Controller层调用**

```java
// UserController.java
@RestController
@RequestMapping("/user")
public class UserController {
    @Autowired
    private UserService userService;
    
    // 分页查询
    @GetMapping("/page")
    public Map<String, Object> getPage(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String name) {
        
        IPage<User> result = userService.getPageByCondition(page, size, name);
        
        // 返回前端的数据结构
        return Map.of(
            "data", result.getRecords(),      // 当前页数据
            "total", result.getTotal(),       // 总记录数
            "page", result.getCurrent(),      // 当前页码
            "size", result.getSize(),         // 每页大小
            "pages", result.getPages()        // 总页数
        );
    }
}
```


## 6. **前端配合的JSON响应**

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "list": [...],      // 当前页数据
    "total": 150,       // 总记录数
    "page": 1,          // 当前页码
    "size": 10,         // 每页大小
    "pages": 15         // 总页数
  }
}
```


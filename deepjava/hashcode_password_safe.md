# 🔐 密码哈希实现速查表

## 📊 哈希算法对比

| 算法 | 输出长度 | 是否加盐 | 迭代次数 | 安全性 | 适用场景 |
|------|---------|---------|---------|--------|----------|
| **hashCode()** | 32位 | ❌ 无 | 1 | ❌ 极低 | **绝不使用** |
| **MD5** | 128位 | ❌ 无 | 1 | ❌ 已破解 | 仅文件校验 |
| **SHA-1** | 160位 | ❌ 无 | 1 | ⚠️ 弱 | 已弃用 |
| **SHA-256** | 256位 | ⚠️ 需手动 | 1 | ⚠️ 中等 | 一般完整性校验 |
| **SHA-512** | 512位 | ⚠️ 需手动 | 1 | ⚠️ 中等 | 一般完整性校验 |
| **PBKDF2** | 可变 | ✅ 内置 | ✅ 可调 | ✅ 强 | **密码存储推荐** |
| **bcrypt** | 192位 | ✅ 内置 | ✅ 可调 | ✅ 强 | **密码存储推荐** |
| **scrypt** | 可变 | ✅ 内置 | ✅ 可调 | ✅ 更强 | 高安全要求 |
| **Argon2** | 可变 | ✅ 内置 | ✅ 可调 | 🏆 最强 | 获奖算法 |

---

## 🚫 绝不使用的实现

```java
// ❌ 极度危险！绝不使用！
public class NeverUseThis {
    
    // 1. hashCode() 哈希
    static String hashWithHashCode(String password) {
        return Integer.toHexString(password.hashCode());
    }
    
    // 2. 无盐MD5
    static String hashWithMD5(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("MD5");
            byte[] hash = md.digest(password.getBytes());
            return HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    
    // 3. 自定义"加密"
    static String fakeEncrypt(String password) {
        return new StringBuilder(password).reverse().toString();
    }
}
```

---

## ⚠️ 学习/演示用实现

```java
// ⚠️ 仅用于学习，不适合生产
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.HexFormat;

public class LearningHash {
    
    // 1. SHA-256 + 随机盐值
    public static String sha256WithSalt(String password) {
        try {
            // 生成随机盐值
            SecureRandom random = new SecureRandom();
            byte[] salt = new byte[16];
            random.nextBytes(salt);
            
            // 加盐哈希
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(salt);
            byte[] hash = digest.digest(password.getBytes());
            
            // 存储格式：盐值:哈希
            return HexFormat.of().formatHex(salt) + ":" + 
                   HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
    
    // 验证
    public static boolean verify(String password, String stored) {
        String[] parts = stored.split(":");
        byte[] salt = HexFormat.of().parseHex(parts[0]);
        byte[] originalHash = HexFormat.of().parseHex(parts[1]);
        
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(salt);
            byte[] newHash = digest.digest(password.getBytes());
            
            return MessageDigest.isEqual(originalHash, newHash);
        } catch (Exception e) {
            return false;
        }
    }
    
    // 2. 简单迭代（慢哈希）
    public static String slowHash(String password, int iterations) {
        String hash = password;
        for (int i = 0; i < iterations; i++) {
            hash = Integer.toHexString(hash.hashCode());  // 仅示例！
        }
        return hash;
    }
}
```

---

## ✅ 生产级别实现

### 方案1：PBKDF2

```java
// ✅ PBKDF2 实现（生产推荐）
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.SecureRandom;
import java.util.Base64;

public class PBKDF2Hash {
    
    // 参数配置
    private static final int ITERATIONS = 310000;  // OWASP推荐
    private static final int KEY_LENGTH = 256;      // 输出长度
    private static final int SALT_LENGTH = 16;      // 盐值长度
    
    // 哈希密码
    public static String hashPassword(String password) {
        try {
            // 生成随机盐值
            SecureRandom random = new SecureRandom();
            byte[] salt = new byte[SALT_LENGTH];
            random.nextBytes(salt);
            
            // PBKDF2哈希
            PBEKeySpec spec = new PBEKeySpec(
                password.toCharArray(), 
                salt, 
                ITERATIONS, 
                KEY_LENGTH
            );
            
            SecretKeyFactory factory = 
                SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            byte[] hash = factory.generateSecret(spec).getEncoded();
            
            // 存储格式：算法:迭代次数:盐值:哈希
            return String.format("PBKDF2:%d:%s:%s",
                ITERATIONS,
                Base64.getEncoder().encodeToString(salt),
                Base64.getEncoder().encodeToString(hash)
            );
            
        } catch (Exception e) {
            throw new RuntimeException("密码哈希失败", e);
        }
    }
    
    // 验证密码
    public static boolean verifyPassword(String password, String storedHash) {
        try {
            // 解析存储字符串
            String[] parts = storedHash.split(":");
            if (!parts[0].equals("PBKDF2")) return false;
            
            int iterations = Integer.parseInt(parts[1]);
            byte[] salt = Base64.getDecoder().decode(parts[2]);
            byte[] originalHash = Base64.getDecoder().decode(parts[3]);
            
            // 重新计算哈希
            PBEKeySpec spec = new PBEKeySpec(
                password.toCharArray(), 
                salt, 
                iterations, 
                originalHash.length * 8
            );
            
            SecretKeyFactory factory = 
                SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256");
            byte[] newHash = factory.generateSecret(spec).getEncoded();
            
            // 安全比较
            return MessageDigest.isEqual(originalHash, newHash);
            
        } catch (Exception e) {
            return false;
        }
    }
}
```

### 方案2：bcrypt

```java
// ✅ bcrypt 实现（需引入依赖）
/*
Maven依赖：
<dependency>
    <groupId>org.mindrot</groupId>
    <artifactId>jbcrypt</artifactId>
    <version>0.4</version>
</dependency>
*/

import org.mindrot.jbcrypt.BCrypt;

public class BCryptHash {
    
    // 工作因子（强度），默认10，每增加1计算时间翻倍
    private static final int WORK_FACTOR = 12;
    
    // 哈希密码
    public static String hashPassword(String password) {
        return BCrypt.hashpw(password, BCrypt.gensalt(WORK_FACTOR));
    }
    
    // 验证密码
    public static boolean verifyPassword(String password, String storedHash) {
        return BCrypt.checkpw(password, storedHash);
    }
    
    // 使用示例
    public static void main(String[] args) {
        String password = "MySecret123";
        
        // 哈希
        String hash = hashPassword(password);
        System.out.println("bcrypt哈希: " + hash);
        // 输出类似: $2a$12$K8H5oQ9pL1qR2sT3uV4wXeY5z6A7b8C9d0E1f2G3h4
        
        // 验证
        System.out.println("正确密码: " + verifyPassword("MySecret123", hash));  // true
        System.out.println("错误密码: " + verifyPassword("wrong", hash));        // false
    }
}
```

### 方案3：Argon2（目前最强）

```java
// 🏆 Argon2 实现（需引入依赖）
/*
Maven依赖：
<dependency>
    <groupId>de.mkammerer</groupId>
    <artifactId>argon2-jvm</artifactId>
    <version>2.11</version>
</dependency>
*/

import de.mkammerer.argon2.Argon2;
import de.mkammerer.argon2.Argon2Factory;

public class Argon2Hash {
    
    private static final int ITERATIONS = 2;
    private static final int MEMORY = 65536;  // 64MB
    private static final int PARALLELISM = 1;
    
    private static final Argon2 argon2 = Argon2Factory.create();
    
    // 哈希密码
    public static String hashPassword(String password) {
        return argon2.hash(ITERATIONS, MEMORY, PARALLELISM, 
                          password.toCharArray());
    }
    
    // 验证密码
    public static boolean verifyPassword(String password, String storedHash) {
        return argon2.verify(storedHash, password.toCharArray());
    }
    
    // 重要：清理内存
    public static void main(String[] args) {
        String password = "MySecret123";
        
        try {
            String hash = hashPassword(password);
            System.out.println("Argon2哈希: " + hash);
            
            boolean match = verifyPassword(password, hash);
            System.out.println("验证结果: " + match);
            
        } finally {
            // 清除密码（安全）
            argon2.wipeArray(password.toCharArray());
        }
    }
}
```

---

## 📈 参数配置参考

### OWASP 推荐参数（2024年）

| 算法 | 迭代次数 | 内存 | 并行度 | 输出长度 |
|------|---------|------|--------|----------|
| **PBKDF2** | 310,000 | - | - | 256位 |
| **bcrypt** | 12-15 | - | - | 192位 |
| **scrypt** | 16,384 | 8 | 1 | 256位 |
| **Argon2id** | 2 | 64MB | 1 | 256位 |

### 迭代次数随时间增长
```
年份  | bcrypt | PBKDF2
2010  | 8      | 50,000
2015  | 10     | 100,000  
2020  | 12     | 200,000
2024  | 14     | 310,000
```

---

## 🔧 工具类：完整解决方案

```java
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public class PasswordHasher {
    
    private static final SecureRandom RANDOM = new SecureRandom();
    
    // 工厂方法：获取合适的哈希器
    public static Hasher getHasher(Algorithm algo) {
        switch (algo) {
            case BCRYPT: return new BCryptHasher();
            case PBKDF2: return new PBKDF2Hasher();
            case ARGON2: return new Argon2Hasher();
            case SHA256: return new SHA256Hasher();  // 仅学习用
            default: throw new IllegalArgumentException("不支持的算法");
        }
    }
    
    // 哈希器接口
    public interface Hasher {
        String hash(String password);
        boolean verify(String password, String hash);
        Algorithm getAlgorithm();
    }
    
    // 算法枚举
    public enum Algorithm {
        BCRYPT, PBKDF2, ARGON2, SHA256
    }
    
    // ========== 具体实现 ==========
    
    // 1. SHA-256 实现（仅学习！）
    public static class SHA256Hasher implements Hasher {
        @Override
        public String hash(String password) {
            try {
                MessageDigest digest = MessageDigest.getInstance("SHA-256");
                byte[] hash = digest.digest(password.getBytes());
                return Base64.getEncoder().encodeToString(hash);
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        }
        
        @Override
        public boolean verify(String password, String hash) {
            return hash(password).equals(hash);
        }
        
        @Override
        public Algorithm getAlgorithm() {
            return Algorithm.SHA256;
        }
    }
    
    // 2. bcrypt 实现（需jbcrypt依赖）
    public static class BCryptHasher implements Hasher {
        private final int workFactor;
        
        public BCryptHasher() {
            this(12);  // 默认12
        }
        
        public BCryptHasher(int workFactor) {
            this.workFactor = workFactor;
        }
        
        @Override
        public String hash(String password) {
            return BCrypt.hashpw(password, BCrypt.gensalt(workFactor));
        }
        
        @Override
        public boolean verify(String password, String hash) {
            return BCrypt.checkpw(password, hash);
        }
        
        @Override
        public Algorithm getAlgorithm() {
            return Algorithm.BCRYPT;
        }
    }
    
    // 使用示例
    public static void main(String[] args) {
        String password = "MySecret123";
        
        // 测试不同算法
        for (Algorithm algo : Algorithm.values()) {
            Hasher hasher = getHasher(algo);
            
            String hash = hasher.hash(password);
            boolean valid = hasher.verify(password, hash);
            
            System.out.println(algo + ":");
            System.out.println("  哈希: " + hash);
            System.out.println("  验证: " + valid);
            System.out.println();
        }
    }
}
```

---

## 📚 速查总结

| 场景 | 推荐算法 | 理由 |
|------|---------|------|
| **生产环境** | bcrypt 或 Argon2 | 简单安全，内置加盐 |
| **Java企业应用** | PBKDF2 | JDK内置，无需依赖 |
| **高安全要求** | Argon2 | 内存硬，抗GPU攻击 |
| **遗留系统升级** | bcrypt | 兼容性好 |
| **学习演示** | SHA-256+盐 | 理解原理 |
| **绝不使用** | MD5, SHA1, hashCode | 已破解或太弱 |

**黄金法则**：
1. ✅ **必须加盐**（每个用户不同）
2. ✅ **必须慢**（可调节迭代次数）
3. ✅ **使用标准库**（不要自己发明）
4. ✅ **定期升级参数**（跟上硬件发展）
import random

class RSA:
    def generate_keys(self):
        def is_prime(num):
            if num < 2:
                return False
            for i in range(2, int(num ** 0.5) + 1):
                if num % i == 0:
                    return False
            return True

        def generate_random_prime():
            while True:
                candidate = random.randint(50, 100)
                if is_prime(candidate):
                    return candidate

        def mod_exp(base, exp, mod):
            result = 1
            base = base % mod
            while exp > 0:
                if exp % 2 == 1:
                    result = (result * base) % mod
                exp //= 2
                base = (base * base) % mod
            return result

        p = generate_random_prime()
        q = generate_random_prime()
        while p == q:
            q = generate_random_prime()
        n = p * q
        phi = (p - 1) * (q - 1)
        e = 17

        d = 0
        for k in range(1, phi):
            if (k * phi + 1) % e == 0:
                d = (k * phi + 1) // e
                break

        self.public_key = (e, n)
        self.private_key = (d, n)
        return self.public_key, self.private_key

    def encrypt(self, public_key, message):
        e, n = public_key
        encrypted = [pow(ord(char), e, n) for char in message]
        return ",".join(map(str, encrypted))

    def decrypt(self, private_key, encrypted_message):
        d, n = private_key
        encrypted_numbers = map(int, encrypted_message.split(","))
        return "".join(chr(pow(num, d, n)) for num in encrypted_numbers)

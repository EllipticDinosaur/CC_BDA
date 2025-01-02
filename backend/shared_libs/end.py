class EnD:
    @staticmethod
    def xor_strings(input_string, key):
        """
        Perform XOR operation between the input string and the key.
        :param input_string: The string to be XOR-ed.
        :param key: The key to XOR with.
        :return: The resulting XOR-ed string.
        """
        output = []
        key_length = len(key)

        for i, char in enumerate(input_string):
            input_char = ord(char)
            key_char = ord(key[i % key_length])
            output.append(chr(input_char ^ key_char))

        return ''.join(output)

    @classmethod
    def encrypt(cls, plaintext, key):
        """
        Encrypt the plaintext using the key with XOR.
        :param plaintext: The string to encrypt.
        :param key: The encryption key.
        :return: The encrypted string.
        """
        return cls.xor_strings(plaintext, key)

    @classmethod
    def decrypt(cls, ciphertext, key):
        """
        Decrypt the ciphertext using the key with XOR.
        :param ciphertext: The encrypted string.
        :param key: The decryption key.
        :return: The decrypted string.
        """
        return cls.xor_strings(ciphertext, key)

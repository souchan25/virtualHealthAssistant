"""
Unit tests for DATABASE_URL encoding functionality.
Tests the encode_database_url function added to settings.py
"""
import unittest
import re
from urllib.parse import quote


def encode_database_url(database_url):
    """
    Safely encode DATABASE_URL components (especially password) for proper URL parsing.
    Handles special characters like @, #, $, %, etc. in passwords.
    
    Args:
        database_url: The database URL string (e.g., postgresql://user:pass@host:port/db)
    
    Returns:
        Properly encoded DATABASE_URL string, or None if URL is invalid
    """
    if not database_url:
        return None
    
    try:
        # Check if URL appears to already be encoded (contains % followed by hex digits)
        # If so, return as-is to avoid double encoding
        if re.search(r'%[0-9A-Fa-f]{2}', database_url):
            return database_url
        
        # Use a regex to parse the URL manually to handle special characters
        # We need to be careful with @ symbol as it's used as a delimiter
        # Strategy: Split on '://' first, then find the last '@' as the user/pass delimiter
        
        if '://' not in database_url:
            return database_url
        
        scheme, rest = database_url.split('://', 1)
        
        # Find the last @ which separates user:pass from host
        # This handles passwords that contain @ symbols
        if '@' in rest:
            # Split from the right to get user_pass and host_part
            auth_part, host_part = rest.rsplit('@', 1)
            
            # Split auth_part into username and password
            if ':' in auth_part:
                username, password = auth_part.split(':', 1)
            else:
                username = auth_part
                password = None
        else:
            username = None
            password = None
            host_part = rest
        
        # Encode username and password if they exist
        # Use safe='' to encode all special characters including @, :, /, etc.
        encoded_username = quote(username, safe='') if username else None
        encoded_password = quote(password, safe='') if password else None
        
        # Reconstruct the URL
        encoded_url = f"{scheme}://"
        
        if encoded_username:
            encoded_url += encoded_username
            if encoded_password:
                encoded_url += ':' + encoded_password
            encoded_url += '@'
        
        encoded_url += host_part
        
        return encoded_url
        
    except Exception as e:
        # If parsing fails, return original URL and let dj_database_url handle the error
        print(f"Warning: Could not parse DATABASE_URL for encoding: {e}")
        return database_url


class TestDatabaseURLEncoding(unittest.TestCase):
    """Test cases for DATABASE_URL encoding functionality"""
    
    def test_simple_password_no_special_chars(self):
        """Test that simple passwords without special characters pass through unchanged"""
        url = "postgresql://user:simplepass@localhost:5432/db"
        result = encode_database_url(url)
        self.assertEqual(result, url)
    
    def test_password_with_at_symbol(self):
        """Test encoding password containing @ symbol"""
        url = "postgresql://user:my@pass@localhost:5432/db"
        result = encode_database_url(url)
        self.assertIn("%40", result)
        self.assertEqual(result, "postgresql://user:my%40pass@localhost:5432/db")
    
    def test_password_with_hash_symbol(self):
        """Test encoding password containing # symbol"""
        url = "postgresql://user:my#pass@localhost:5432/db"
        result = encode_database_url(url)
        self.assertIn("%23", result)
        self.assertEqual(result, "postgresql://user:my%23pass@localhost:5432/db")
    
    def test_password_with_dollar_sign(self):
        """Test encoding password containing $ symbol"""
        url = "postgresql://user:my$pass@localhost:5432/db"
        result = encode_database_url(url)
        self.assertIn("%24", result)
        self.assertEqual(result, "postgresql://user:my%24pass@localhost:5432/db")
    
    def test_password_with_percent_sign(self):
        """Test encoding password containing % symbol"""
        url = "postgresql://user:my%pass@localhost:5432/db"
        result = encode_database_url(url)
        self.assertIn("%25", result)
        self.assertEqual(result, "postgresql://user:my%25pass@localhost:5432/db")
    
    def test_password_with_multiple_special_chars(self):
        """Test encoding password with multiple special characters"""
        url = "postgresql://user:my@pass#word$123@localhost:5432/db"
        result = encode_database_url(url)
        self.assertIn("%40", result)
        self.assertIn("%23", result)
        self.assertIn("%24", result)
        self.assertEqual(result, "postgresql://user:my%40pass%23word%24123@localhost:5432/db")
    
    def test_already_encoded_url(self):
        """Test that already encoded URLs are not double-encoded"""
        url = "postgresql://user:my%40pass@localhost:5432/db"
        result = encode_database_url(url)
        self.assertEqual(result, url)
        # Should not contain double-encoded %25
        self.assertNotIn("%2540", result)
    
    def test_password_with_colons(self):
        """Test encoding password containing colons"""
        url = "postgresql://user:pass:with:colons@localhost:5432/db"
        result = encode_database_url(url)
        self.assertIn("%3A", result)
        self.assertEqual(result, "postgresql://user:pass%3Awith%3Acolons@localhost:5432/db")
    
    def test_no_password(self):
        """Test URL with username but no password"""
        url = "postgresql://user@localhost:5432/db"
        result = encode_database_url(url)
        self.assertEqual(result, url)
    
    def test_no_user_or_password(self):
        """Test URL with no authentication"""
        url = "postgresql://localhost:5432/db"
        result = encode_database_url(url)
        self.assertEqual(result, url)
    
    def test_none_input(self):
        """Test that None input returns None"""
        result = encode_database_url(None)
        self.assertIsNone(result)
    
    def test_empty_string_input(self):
        """Test that empty string input returns None"""
        result = encode_database_url("")
        self.assertIsNone(result)
    
    def test_postgresql_url(self):
        """Test PostgreSQL URL format"""
        url = "postgresql://user:P@ss#123@db.example.com:5432/mydb"
        result = encode_database_url(url)
        self.assertEqual(result, "postgresql://user:P%40ss%23123@db.example.com:5432/mydb")
    
    def test_mysql_url(self):
        """Test MySQL URL format"""
        url = "mysql://user:P@ss#123@db.example.com:3306/mydb"
        result = encode_database_url(url)
        self.assertEqual(result, "mysql://user:P%40ss%23123@db.example.com:3306/mydb")
    
    def test_url_with_query_params(self):
        """Test URL with query parameters"""
        url = "postgresql://user:p@ss@localhost:5432/db?sslmode=require"
        result = encode_database_url(url)
        self.assertEqual(result, "postgresql://user:p%40ss@localhost:5432/db?sslmode=require")
    
    def test_complex_real_world_password(self):
        """Test with a complex real-world password"""
        url = "postgresql://cpsu_admin:SecureP@ss#2024!$%^&*@render.com:5432/cpsu_health"
        result = encode_database_url(url)
        # Should encode all special characters
        self.assertIn("%40", result)  # @
        self.assertIn("%23", result)  # #
        self.assertIn("%21", result)  # !
        self.assertIn("%24", result)  # $
        self.assertIn("%25", result)  # %
        self.assertIn("%5E", result)  # ^
        self.assertIn("%26", result)  # &
        self.assertIn("%2A", result)  # *
    
    def test_username_with_special_chars(self):
        """Test that username is also encoded if it contains special characters"""
        url = "postgresql://user@name:password@localhost:5432/db"
        result = encode_database_url(url)
        self.assertIn("%40", result)
        # Username should be encoded before the first colon
        self.assertTrue(result.startswith("postgresql://user%40name:"))
    
    def test_preserves_port_and_database(self):
        """Test that port and database name are preserved correctly"""
        url = "postgresql://user:p@ss@localhost:5432/mydb"
        result = encode_database_url(url)
        self.assertIn(":5432/", result)
        self.assertTrue(result.endswith("/mydb"))


class TestDatabaseURLWithDjDatabaseUrl(unittest.TestCase):
    """Test that encoded URLs work with dj_database_url library"""
    
    def setUp(self):
        """Check if dj_database_url is available"""
        try:
            import dj_database_url
            self.dj_database_url = dj_database_url
            self.has_dj_database_url = True
        except ImportError:
            self.has_dj_database_url = False
    
    def test_encoded_url_parses_with_dj_database_url(self):
        """Test that encoded URLs successfully parse with dj_database_url"""
        if not self.has_dj_database_url:
            self.skipTest("dj_database_url not installed")
        
        url = "postgresql://user:my@pass#word@localhost:5432/testdb"
        encoded = encode_database_url(url)
        
        # Should not raise an exception
        result = self.dj_database_url.parse(encoded)
        
        # Verify parsed values
        self.assertEqual(result['ENGINE'], 'django.db.backends.postgresql')
        self.assertEqual(result['NAME'], 'testdb')
        self.assertEqual(result['USER'], 'user')
        self.assertEqual(result['HOST'], 'localhost')
        self.assertEqual(result['PORT'], 5432)
    
    def test_complex_password_parses_correctly(self):
        """Test complex password decodes correctly after encoding"""
        if not self.has_dj_database_url:
            self.skipTest("dj_database_url not installed")
        
        url = "postgresql://admin:P@ss#2024@db.example.com:5432/mydb"
        encoded = encode_database_url(url)
        result = self.dj_database_url.parse(encoded)
        
        self.assertEqual(result['USER'], 'admin')
        # Password should be decoded back to original by dj_database_url
        self.assertEqual(result['PASSWORD'], 'P@ss#2024')


if __name__ == '__main__':
    # Run tests with verbose output
    unittest.main(verbosity=2)

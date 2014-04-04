Public Class Passwords
    ' Passwords must never be stored as plaintext - anyone can open the database they are stored in and simply read the password.
    ' We are not trying to protect experiments from an attacker - this is not part of the business requirements - but we must
    ' protect users who may use a passphrase for other services (e.g. email). Using a one way hashing algorithm with a salt, as we do here,
    ' means that it is impossible (concerning practical limitations) for someone to discover any passphrases used by users.

    ' Add a private constructor so this class cannot be instantiated. VB.NET does not support static/shared classes.
    Private Sub New()
    End Sub

    ' Create only one instance of the cryptographically secure RNG we can reuse.
    Private Shared ReadOnly cryptRandG As New System.Security.Cryptography.RNGCryptoServiceProvider
    ' Defines the length of the salt in bytes before it is converted to a String. 8 creates 12.
    Private Const saltSize As Integer = 8

    ' Generates a random salt to be appended to the raw password string.
    Public Shared Function generateSalt() As String
        Dim randBytes(saltSize) As Byte
        cryptRandG.GetBytes(randBytes)
        Return Convert.ToBase64String(randBytes)
    End Function

    ' Hashes a given password using a randomly generated salt.
    Public Shared Function cryptPassword(ByVal pass As String) As HashedPassword
        Return Passwords.cryptPassword(pass, Passwords.generateSalt())
    End Function

    ' Hashes a given password using the given salt.
    Public Shared Function cryptPassword(ByVal pass As String, ByVal salt As String) As HashedPassword
        Dim result As HashedPassword
        Dim sha256 As New System.Security.Cryptography.SHA256Managed

        result.passwordSalt = salt
        pass = pass & salt
        result.passwordHash = Convert.ToBase64String(sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(pass)))

        Return (result)
    End Function

    'Compares a given raw password against a hashed password.
    Public Shared Function checkPassword(ByVal input As String, ByVal hashed As HashedPassword) As Boolean
        Dim hashedInput As HashedPassword = Passwords.cryptPassword(input, hashed.passwordSalt)

        If hashedInput.passwordHash = hashed.passwordHash Then
            Return True
        Else
            Return False
        End If
    End Function

    Public Structure HashedPassword
        Public passwordHash As String
        Public passwordSalt As String
    End Structure
End Class

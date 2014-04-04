Public Class PasswordConfirmationBox
    ' Should be displayed using ShowDialog(). Return value of ignore means password cleared, OK means correct, No means incorrect.
    Protected ReadOnly pass As Passwords.HashedPassword

    Public Sub New(ByVal hashedPass As Passwords.HashedPassword)
        Me.pass = hashedPass
        Me.InitializeComponent()
    End Sub

    Private Sub PasswordBox_TextChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles PasswordBox.TextChanged
        If String.IsNullOrEmpty(Me.PasswordBox.Text) Then
            Me.ConfirmButton.Enabled = False
        Else
            Me.ConfirmButton.Enabled = True
        End If
    End Sub

    Private Sub ClearBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ClearBtn.Click
        Me.DialogResult = DialogResult.Ignore
    End Sub

    Private Sub ConfirmButton_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ConfirmButton.Click
        If Passwords.checkPassword(Me.PasswordBox.Text, Me.pass) Then
            Me.DialogResult = DialogResult.OK
        Else
            Me.DialogResult = DialogResult.No
        End If
    End Sub

    Private Sub PasswordConfirmationBox_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load

    End Sub
End Class
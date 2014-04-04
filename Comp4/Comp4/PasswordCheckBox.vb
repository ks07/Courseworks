Public Class PasswordCheckBox
    Inherits PasswordConfirmationBox
    ' Inherit the confirmation dialog, as we can re-use the code and just change the text shown.

    Public Sub New(ByVal hashedPass As Passwords.HashedPassword)
        MyBase.New(hashedPass)
        Me.DialogLabel.Text = "Please type the password for this experiment. Press the " & _
            Environment.NewLine & "cancel button to return to the experiment list."
        Me.ClearBtn.Text = "Cancel"
    End Sub

End Class

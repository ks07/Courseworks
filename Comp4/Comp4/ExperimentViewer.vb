Public Class ExperimentViewer
    Private ex As Experiment
    Private passChanged As Boolean

    Public Sub New(ByRef ex As Experiment)
        InitializeComponent()
        Me.ex = ex
    End Sub

    Private Sub ExperimentViewer_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ' Setup the initial values of the form.
        Me.Text &= Me.ex.Name
        Me.ExpDataView.DataSource = Me.ex.ExperimentData
        Me.UpdateDetails()

        ' Set default export file
        ' Strip invalid filename characters from experiment name
        Dim filename As String = Me.ex.Name.Trim()

        For Each invalidChar In IO.Path.GetInvalidFileNameChars
            filename = filename.Replace(invalidChar, "")
        Next

        If String.IsNullOrWhiteSpace(filename) Then
            ' Experiment name contains no valid characters, so use a generic name.
            filename = "ExportedExperiment"
        ElseIf filename.Length > 16 Then
            ' Trim filename to a sensible length.
            filename = filename.Substring(0, 16)
        End If

        Me.ExportFileDialog.FileName = System.Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments) & System.IO.Path.DirectorySeparatorChar & filename & ".csv"
        Me.ExportFileDialog.Filter = "CSV (*.csv)|*.csv|Plain Text (*.txt)|*.txt"

        Me.passChanged = False
    End Sub

    ' As we have nothing to compare the password to, we must assume that any changes to the password box means it is new.
    Private Sub TxtPass_TextChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles TxtPass.TextChanged
        Me.passChanged = True
    End Sub

    Private Sub ApplyChanges()
        ' Apply the changes to the experiment object.
        Me.ex.Name = Me.TxtTitle.Text
        Me.ex.Category = Me.TxtCategory.Text
        Me.ex.Creator = Me.TxtCreator.Text
        Me.ex.CreationDate = Me.RecordDateTime.Value
        Me.ex.Description = Me.TxtDesc.Text

        ' Check if the state of the password has been changed.
        If Me.PassCheckBox.Checked <> Me.ex.PasswordProtected Then
            If Me.PassCheckBox.Checked And Me.passChanged Then
                ' The user has enabled a password and has set a value.
                Me.ex.Password = Passwords.cryptPassword(Me.TxtPass.Text)
            ElseIf Me.PassCheckBox.Checked And Not Me.passChanged Then
                ' The user has enabled a password but has not changed from the default value.
                MsgBox("You must set a password before you can continue. Otherwise, please disable password protection.", MsgBoxStyle.OkOnly + MsgBoxStyle.Exclamation, "Warning - You Must Set a Password")
            Else
                ' The user has disabled the password.
                Me.ex.PasswordProtected = False
            End If
        ElseIf Me.passChanged And Me.ex.PasswordProtected Then
            ' The user hasn't toggled the password, but has modified the password value.
            Me.ex.Password = Passwords.cryptPassword(Me.TxtPass.Text)
        End If
    End Sub

    Private Sub PassCheckBox_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles PassCheckBox.CheckedChanged
        Me.TxtPass.Enabled = Me.PassCheckBox.Checked
    End Sub

    Private Sub ExitBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ExitBtn.Click
        Me.ApplyChanges()

        ' If a password is set and changed, make sure the user knows it before letting them save it
        If Me.ex.PasswordProtected And Me.passChanged Then
            Dim checkPass As New PasswordConfirmationBox(Me.ex.Password)
            Select Case checkPass.ShowDialog()
                Case DialogResult.No
                    MsgBox("Password was incorrect. Please re-enter your chosen password and try again.", MsgBoxStyle.OkOnly + MsgBoxStyle.Critical, "Password Incorrect")
                    ' Cancel the save and exit operation.
                    Return
                Case DialogResult.Ignore
                    ' Disable the password and continue with save.
                    Me.ex.PasswordProtected = False
            End Select
        End If

        ' We don't need to save anything more than the metadata, as the user cannot edit the recorded data.
        DataHandler.getInstance().saveModifiedExperimentMetadata(ex, Me.passChanged)

        Me.Close()
    End Sub

    Private Sub ExportBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ExportBtn.Click
        If Me.ExportFileDialog.ShowDialog() = DialogResult.OK Then
            Me.ex.exportAsCSV(Me.ExportFileDialog.FileName)
        End If
    End Sub

    Private Sub RevertBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RevertBtn.Click
        Me.passChanged = False
        Me.UpdateDetails()
    End Sub

    Private Sub UpdateDetails()
        Me.RecordDateTime.Value = Me.ex.CreationDate
        Me.TxtTitle.Text = Me.ex.Name
        Me.TxtCreator.Text = Me.ex.Creator
        Me.TxtCategory.Text = Me.ex.Category
        Me.TxtDesc.Text = Me.ex.Description

        If Me.ex.PasswordProtected Then
            Me.PassCheckBox.Checked = True
            ' Set a placeholder password, as we don't have the original password.
            ' Even if we did, we would not want to reveal it's length.
            Me.TxtPass.Text = "********"
            Me.TxtPass.Enabled = True
        Else
            Me.TxtPass.Text = ""
            Me.TxtPass.Enabled = False
            Me.PassCheckBox.Checked = False
        End If
    End Sub

End Class
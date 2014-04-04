Public Class RecordForm
    Private ex As Experiment
    Private readyToSave As Boolean = False
    Private WithEvents SerialPortBackgroundWorker As PortBackgroundWorker

    Private Sub Record_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Me.RecordDateTime.Value = DateTime.Now
        Me.SerialPortBackgroundWorker = New PortBackgroundWorker()
        Me.SerialPortBackgroundWorker.WorkerReportsProgress = True
        Me.SerialPortBackgroundWorker.WorkerSupportsCancellation = True
        Me.SerialPort.PortName = OptionsDialog.SerialPort
        Me.SerialPort.Open()
    End Sub

    Private Sub ConnectBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ConnectBtn.Click
        Me.ProgBar.Style = ProgressBarStyle.Continuous
        Me.ConnectBtn.Enabled = False
        Me.SerialPortBackgroundWorker.RunWorkerAsync()
    End Sub

    Private Sub DisplayExperiment()
        Me.RecordDateTime.Value = Me.ex.CreationDate
        Me.TxtTitle.Text = Me.ex.Name
        Me.TxtCreator.Text = Me.ex.Creator
        Me.TxtCategory.Text = Me.ex.Category
    End Sub

    Private Sub ExitBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ExitBtn.Click
        If Me.readyToSave Then
            ' Apply changes before saving.
            Me.ApplyChanges()

            ' If a password is set, make sure the user knows it before letting them save it
            If Me.ex.PasswordProtected Then
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

            ' Save the new experiment.
            DataHandler.getInstance().saveNewExperiment(Me.ex)

            ' Close the window.
            Me.Close()
        Else
            ' Cancel the port task.
            Me.SerialPortBackgroundWorker.CancelAsync()

            ' Notify the user that we are cancelling the task.
            ' It may take some time if the port is blocking on a read operation.
            Me.UpdateProgress("Cancelling...", 100)
        End If
    End Sub

    Private Sub ApplyBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ApplyBtn.Click
        Me.ApplyChanges()
    End Sub

    Private Sub ApplyChanges()
        ' Apply the changes to the experiment object.
        Me.ex.Name = Me.TxtTitle.Text
        Me.ex.Category = Me.TxtCategory.Text
        Me.ex.Creator = Me.TxtCreator.Text
        Me.ex.CreationDate = Me.RecordDateTime.Value
        Me.ex.Description = Me.TxtDesc.Text

        If Me.PassCheckBox.Checked Then
            ex.Password = Passwords.cryptPassword(Me.TxtPass.Text)
        End If
    End Sub

    ' The progress bar will only be representative, and not an accurate description of the time remaining, as we have no
    ' way of telling how much more data we need to receive. This is only to show the user that communication is in progress.
    Public Sub UpdateProgress(ByVal message As String, ByVal percentage As Integer)
        Me.StatusLabel.Text = message
        Me.ProgBar.Value = percentage
    End Sub

    Public Sub UpdateProgress(ByVal percentage As Integer)
        Me.ProgBar.Value = percentage
    End Sub

    Private Sub PassCheckBox_CheckedChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles PassCheckBox.CheckedChanged
        If Me.PassCheckBox.Checked Then
            Me.TxtPass.Enabled = True
        Else
            Me.TxtPass.Text = ""
            Me.TxtPass.Enabled = False
        End If
    End Sub

    ' BackgroundWorker's code here. All the code in this subroutine runs in a different thread, which means the dialog box remains responsive.
    Private Sub SerialPortBackgroundWorker_DoWork(ByVal sender As PortBackgroundWorker, ByVal e As System.ComponentModel.DoWorkEventArgs) Handles SerialPortBackgroundWorker.DoWork
        Dim dataParser As DataParser = New MetadataParser(Me.SerialPort, sender)

        sender.ReportProgress(0, New PortBackgroundWorker.SerialWorkerState("Connecting..."))

        Try
            Do
                dataParser = dataParser.read()
            Loop Until dataParser.getCompletionStatus() <> dataParser.CompletionStatus.PENDING

            Select Case dataParser.getCompletionStatus()
                Case dataParser.CompletionStatus.COMPLETE
                    e.Result = dataParser.getExperiment()
                Case dataParser.CompletionStatus.CANCELLED
                    e.Cancel = True
            End Select
        Catch ex As Exception
            ' If a read blocks long enough to exceed the timeout value, we must catch the exception and cancel the record operation.
            ' If the user has clicked cancel, the cancelled status should take precedence. The user may know that they have configured their equipment incorrectly.
            If sender.CancellationPending Then
                e.Cancel = True
            Else
                e.Result = ex
            End If
        End Try
    End Sub

    Private Sub SerialPortBackgroundWorker_RunWorkerCompleted(ByVal sender As PortBackgroundWorker, ByVal e As System.ComponentModel.RunWorkerCompletedEventArgs) Handles SerialPortBackgroundWorker.RunWorkerCompleted
        ' Close the serial port if not done so already.
        If Me.SerialPort.IsOpen Then
            Me.SerialPort.Close()
        End If

        If e.Cancelled Then
            ' The task was cancelled, so close the form.
            Me.Close()
        Else
            Dim ex As Experiment = TryCast(e.Result, Experiment)

            If Not IsNothing(ex) Then
                Me.ex = ex

                Me.UpdateProgress("Transfer complete.", 100)
                Me.DisplayExperiment()

                ' Enable and disable controls.
                Me.ConnectBtn.Enabled = False
                Me.RecordDateTime.Enabled = True
                Me.TxtCategory.Enabled = True
                Me.TxtCreator.Enabled = True
                Me.TxtTitle.Enabled = True
                Me.ApplyBtn.Enabled = True
                Me.PassCheckBox.Enabled = True
                Me.TxtDesc.Enabled = True
                Me.ExitBtn.Text = "Save and Exit"
                Me.readyToSave = True
            Else
                ' This will be the case if the BackgroundWorker does not set the result as an Experiment object.
                ' It could also be the case if the serial port throws an exception meaning we cannot continue.
                ' Show an error message and return to the main menu.
                MsgBox("Fatal error when recording experiment data. Please check the connection to the logging device and try again.", MsgBoxStyle.OkOnly + MsgBoxStyle.Critical, "Experiment Recording Failed")
                Me.Close()
            End If
        End If

    End Sub

    Private Sub SerialPortBackgroundWorker_ProgressChanged(ByVal sender As PortBackgroundWorker, ByVal e As System.ComponentModel.ProgressChangedEventArgs) Handles SerialPortBackgroundWorker.ProgressChanged
        ' The progress bar will only be representative, and not an accurate description of the time remaining, as we have no
        ' way of telling how much more data we need to receive. This is only to show the user that communication is in progress.
        Dim workerState As PortBackgroundWorker.SerialWorkerState = TryCast(e.UserState, PortBackgroundWorker.SerialWorkerState)

        If Not IsNothing(workerState) Then
            Me.UpdateProgress(workerState.ProgressText, e.ProgressPercentage)
        Else
            Me.ProgBar.Value = e.ProgressPercentage
        End If
    End Sub
End Class
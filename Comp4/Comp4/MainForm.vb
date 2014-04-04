Public Class MainForm
    Private Sub RecordBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles RecordBtn.Click
        Dim recordForm As New RecordForm()
        recordForm.ShowDialog()
    End Sub

    Private Sub MainForm_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        ' Initialise the database. We do this now so that errors with creating/loading the database does not lose data later while recording.
        DataHandler.getInstance()
    End Sub

    Private Sub ViewBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles ViewBtn.Click
        Dim vForm As New ViewForm()
        ' We don't want the user to be able to record and view at the same time, so use a dialog to disable the main window.
        vForm.ShowDialog()
    End Sub

    Private Sub OptionsBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles OptionsBtn.Click
        Dim opt As New OptionsDialog()
        opt.ShowDialog()
    End Sub
End Class

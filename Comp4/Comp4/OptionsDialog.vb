Imports System.Windows.Forms

Public Class OptionsDialog
    Private Shared DBLocation As String
    Private Shared ActivePort As String

    Public Shared ReadOnly Property SerialPort As String
        Get
            If String.IsNullOrWhiteSpace(ActivePort) Then
                ' Default setting.
                Return System.IO.Ports.SerialPort.GetPortNames()(0)
            Else
                Return ActivePort
            End If
        End Get
    End Property

    Public Shared ReadOnly Property DatabaseLocation As String
        Get
            If String.IsNullOrWhiteSpace(DBLocation) Then
                ' Default setting.
                Return System.Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments) & System.IO.Path.DirectorySeparatorChar & "ExperimentDB.mdb"
            Else
                Return DBLocation
            End If
        End Get
    End Property

    Private Sub OK_Button_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles OK_Button.Click
        ' If no file was specified in the file dialog, keep the previous value.
        If Not String.IsNullOrWhiteSpace(Me.SaveFileDialog.FileName) Then
            ' Check if the new location matches the old.
            Dim newDB As Boolean = Not DatabaseLocation.Equals(Me.SaveFileDialog.FileName)

            If newDB Then
                ' Save the previous DB location in case we need to revert it due to an error.
                Dim tmpDB As String = DBLocation
                ' Replace current options with modified options.
                DBLocation = Me.SaveFileDialog.FileName
                ' Database location has been changed, so we must reload the database.
                If Not DataHandler.getInstance().reload() Then
                    ' DB file could not be loaded.
                    MsgBox("Failed to load experiment database file! Please select a different file, or create a new one.", MsgBoxStyle.Critical + MsgBoxStyle.OkOnly, "Invalid Database File")

                    'Revert the DB location.
                    DBLocation = tmpDB

                    'Cancel the close operation so the user can make appropriate changes.
                    Return
                End If
            End If
        End If

        ' If nothing was selected, keep the previous value.
        If Not IsNothing(Me.PortListBox.SelectedItem) Then
            ActivePort = CStr(Me.PortListBox.SelectedItem)
        End If

        Me.DialogResult = System.Windows.Forms.DialogResult.OK
        Me.Close()
    End Sub

    Private Sub Cancel_Button_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles Cancel_Button.Click
        Me.DialogResult = System.Windows.Forms.DialogResult.Cancel
        Me.Close()
    End Sub

    Private Sub OptionsDialog_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Me.SaveFileDialog.OverwritePrompt = False
        Me.SaveFileDialog.Filter = "Database Files (*.mdb)|*.mdb|All files (*.*)|*.*"
        Me.PortListBox.Items.Clear()
        Me.PortListBox.Items.AddRange(System.IO.Ports.SerialPort.GetPortNames())
    End Sub

    Private Sub DbBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles DbBtn.Click
        Me.SaveFileDialog.ShowDialog()
    End Sub
End Class

Public Class ViewForm

    Private Sub ViewForm_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        Me.InitialiseList()
    End Sub

    Private Sub InitialiseList()
        Me.TreeView.Nodes.Clear()

        Dim expList As List(Of Experiment) = DataHandler.getInstance().getExperimentList()
        Me.ClearSummary()

        For Each ex As Experiment In expList
            If ex.Category = "" Then
                Dim exChildNode As New TreeNodeExperiment(ex.Name, ex)

                Me.TreeView.Nodes.Add(exChildNode)
            Else
                Dim catNode As TreeNode
                If Not Me.TreeView.Nodes.ContainsKey(ex.Category) Then
                    ' Add the node with a key so we can easily check it's existence later. The key is the category name.
                    catNode = Me.TreeView.Nodes.Add(ex.Category, ex.Category)
                Else
                    catNode = Me.TreeView.Nodes.Item(ex.Category)
                End If

                Dim exChildNode As New TreeNodeExperiment(ex.Name, ex)

                catNode.Nodes.Add(exChildNode)
            End If
        Next

        Me.TreeView.ExpandAll()
    End Sub

    Private Sub ClearSummary()
        Me.CreatorTxt.Text = ""
        Me.CategoryTxt.Text = ""
        Me.DescTxt.Text = ""
        Me.DateTxt.Value = Date.Now

        Me.DeleteBtn.Enabled = False
        Me.OpenBtn.Enabled = False
    End Sub

    Private Sub DisplaySummary(ByVal selectedExperiment As Experiment)
        Me.CreatorTxt.Text = selectedExperiment.Creator
        Me.CategoryTxt.Text = selectedExperiment.Category
        Me.DescTxt.Text = selectedExperiment.Description
        Me.DateTxt.Value = selectedExperiment.CreationDate

        Me.DeleteBtn.Enabled = True
        Me.OpenBtn.Enabled = True
    End Sub

    Private Sub OpenBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles OpenBtn.Click
        If TypeOf Me.TreeView.SelectedNode Is TreeNodeExperiment Then
            Dim TNE As TreeNodeExperiment = Me.TreeView.SelectedNode
            Dim selectedExperiment As Experiment = TNE.ex
            Dim accessResult As Windows.Forms.DialogResult

            If selectedExperiment.PasswordProtected Then
                Dim pcb As New PasswordCheckBox(selectedExperiment.Password)

                accessResult = pcb.ShowDialog()
            Else
                accessResult = Windows.Forms.DialogResult.OK
            End If

            If accessResult = Windows.Forms.DialogResult.OK Then
                Try
                    DataHandler.getInstance().fillExperimentData(selectedExperiment)
                Catch
                    MsgBox("Experiment data could not be found in the database!", MsgBoxStyle.Critical + MsgBoxStyle.OkOnly, "Experiment Error")
                    Return
                End Try

                Dim dbg As New ExperimentViewer(selectedExperiment)
                ' Call the viewer as a dialog so the list stops responding while in edit mode.
                dbg.ShowDialog()

                ' Update the view form list.
                Me.InitialiseList()
            ElseIf accessResult = Windows.Forms.DialogResult.Ignore Then
                MsgBox("This experiment is password protected. You must supply the correct password to continue.", MsgBoxStyle.OkOnly + MsgBoxStyle.Information, "Password Protected")
            Else
                MsgBox("Password Incorrect, please try again.", MsgBoxStyle.OkOnly + MsgBoxStyle.Critical, "Incorrect Password")
            End If
        End If
    End Sub

    Private Sub CloseBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles CloseBtn.Click
        Me.Close()
    End Sub

    Private Sub DeleteBtn_Click(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles DeleteBtn.Click
        If TypeOf Me.TreeView.SelectedNode Is TreeNodeExperiment Then
            Dim TNE As TreeNodeExperiment = Me.TreeView.SelectedNode
            Dim selectedExperiment As Experiment = TNE.ex
            Dim accessResult As Windows.Forms.DialogResult

            If selectedExperiment.PasswordProtected Then
                Dim pcb As New PasswordCheckBox(selectedExperiment.Password)

                accessResult = pcb.ShowDialog()
            Else
                accessResult = Windows.Forms.DialogResult.OK
            End If

            If accessResult = Windows.Forms.DialogResult.OK Then
                DataHandler.getInstance().deleteExperiment(selectedExperiment)

                ' Update the view form list.
                Me.InitialiseList()
            ElseIf accessResult = Windows.Forms.DialogResult.Ignore Then
                MsgBox("This experiment is password protected. You must supply the correct password to continue.", MsgBoxStyle.OkOnly + MsgBoxStyle.Information, "Password Protected")
            Else
                MsgBox("Password Incorrect, please try again.", MsgBoxStyle.OkOnly + MsgBoxStyle.Critical, "Incorrect Password")
            End If
        End If
    End Sub

    Private Sub TreeView_AfterSelect(ByVal sender As System.Object, ByVal e As System.Windows.Forms.TreeViewEventArgs) Handles TreeView.AfterSelect
        ' If the user has selected a child node, it will be a TreeNodeExperiment.
        If TypeOf Me.TreeView.SelectedNode Is TreeNodeExperiment Then
            Dim TNE As TreeNodeExperiment = Me.TreeView.SelectedNode

            Me.DisplaySummary(TNE.ex)
        Else
            ' If the user hasn't got an experiment selected, the display should be cleared.
            Me.ClearSummary()
        End If
    End Sub

    Private Class TreeNodeExperiment
        Inherits TreeNode
        Public ReadOnly ex As Experiment

        Public Sub New(ByVal text As String, ByRef ex As Experiment)
            MyBase.New(text)
            Me.ex = ex
        End Sub

    End Class
End Class
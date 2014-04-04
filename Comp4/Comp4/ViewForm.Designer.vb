<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class ViewForm
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.CreatorLbl = New System.Windows.Forms.Label()
        Me.Label2 = New System.Windows.Forms.Label()
        Me.DescLbl = New System.Windows.Forms.Label()
        Me.CreatorTxt = New System.Windows.Forms.TextBox()
        Me.CategoryTxt = New System.Windows.Forms.TextBox()
        Me.DescTxt = New System.Windows.Forms.TextBox()
        Me.CloseBtn = New System.Windows.Forms.Button()
        Me.DeleteBtn = New System.Windows.Forms.Button()
        Me.OpenBtn = New System.Windows.Forms.Button()
        Me.DateLbl = New System.Windows.Forms.Label()
        Me.DateTxt = New System.Windows.Forms.DateTimePicker()
        Me.TreeView = New System.Windows.Forms.TreeView()
        Me.SuspendLayout()
        '
        'CreatorLbl
        '
        Me.CreatorLbl.AutoSize = True
        Me.CreatorLbl.Location = New System.Drawing.Point(12, 169)
        Me.CreatorLbl.Name = "CreatorLbl"
        Me.CreatorLbl.Size = New System.Drawing.Size(44, 13)
        Me.CreatorLbl.TabIndex = 1
        Me.CreatorLbl.Text = "Creator:"
        '
        'Label2
        '
        Me.Label2.AutoSize = True
        Me.Label2.Location = New System.Drawing.Point(12, 195)
        Me.Label2.Name = "Label2"
        Me.Label2.Size = New System.Drawing.Size(52, 13)
        Me.Label2.TabIndex = 2
        Me.Label2.Text = "Category:"
        '
        'DescLbl
        '
        Me.DescLbl.AutoSize = True
        Me.DescLbl.Location = New System.Drawing.Point(10, 221)
        Me.DescLbl.Name = "DescLbl"
        Me.DescLbl.Size = New System.Drawing.Size(63, 13)
        Me.DescLbl.TabIndex = 3
        Me.DescLbl.Text = "Description:"
        '
        'CreatorTxt
        '
        Me.CreatorTxt.Location = New System.Drawing.Point(79, 166)
        Me.CreatorTxt.Name = "CreatorTxt"
        Me.CreatorTxt.ReadOnly = True
        Me.CreatorTxt.Size = New System.Drawing.Size(193, 20)
        Me.CreatorTxt.TabIndex = 4
        '
        'CategoryTxt
        '
        Me.CategoryTxt.Location = New System.Drawing.Point(79, 192)
        Me.CategoryTxt.Name = "CategoryTxt"
        Me.CategoryTxt.ReadOnly = True
        Me.CategoryTxt.Size = New System.Drawing.Size(193, 20)
        Me.CategoryTxt.TabIndex = 5
        '
        'DescTxt
        '
        Me.DescTxt.AcceptsReturn = True
        Me.DescTxt.Location = New System.Drawing.Point(79, 218)
        Me.DescTxt.Multiline = True
        Me.DescTxt.Name = "DescTxt"
        Me.DescTxt.ReadOnly = True
        Me.DescTxt.ScrollBars = System.Windows.Forms.ScrollBars.Vertical
        Me.DescTxt.Size = New System.Drawing.Size(193, 94)
        Me.DescTxt.TabIndex = 6
        '
        'CloseBtn
        '
        Me.CloseBtn.Location = New System.Drawing.Point(192, 318)
        Me.CloseBtn.Name = "CloseBtn"
        Me.CloseBtn.Size = New System.Drawing.Size(80, 23)
        Me.CloseBtn.TabIndex = 7
        Me.CloseBtn.Text = "Close"
        Me.CloseBtn.UseVisualStyleBackColor = True
        '
        'DeleteBtn
        '
        Me.DeleteBtn.Enabled = False
        Me.DeleteBtn.Location = New System.Drawing.Point(99, 318)
        Me.DeleteBtn.Name = "DeleteBtn"
        Me.DeleteBtn.Size = New System.Drawing.Size(87, 23)
        Me.DeleteBtn.TabIndex = 8
        Me.DeleteBtn.Text = "Delete"
        Me.DeleteBtn.UseVisualStyleBackColor = True
        '
        'OpenBtn
        '
        Me.OpenBtn.Enabled = False
        Me.OpenBtn.Location = New System.Drawing.Point(13, 318)
        Me.OpenBtn.Name = "OpenBtn"
        Me.OpenBtn.Size = New System.Drawing.Size(80, 23)
        Me.OpenBtn.TabIndex = 9
        Me.OpenBtn.Text = "Open/Edit"
        Me.OpenBtn.UseVisualStyleBackColor = True
        '
        'DateLbl
        '
        Me.DateLbl.AutoSize = True
        Me.DateLbl.Location = New System.Drawing.Point(12, 146)
        Me.DateLbl.Name = "DateLbl"
        Me.DateLbl.Size = New System.Drawing.Size(33, 13)
        Me.DateLbl.TabIndex = 10
        Me.DateLbl.Text = "Date:"
        '
        'DateTxt
        '
        Me.DateTxt.Enabled = False
        Me.DateTxt.Location = New System.Drawing.Point(79, 140)
        Me.DateTxt.Name = "DateTxt"
        Me.DateTxt.Size = New System.Drawing.Size(193, 20)
        Me.DateTxt.TabIndex = 11
        '
        'TreeView
        '
        Me.TreeView.Location = New System.Drawing.Point(12, 12)
        Me.TreeView.Name = "TreeView"
        Me.TreeView.Size = New System.Drawing.Size(260, 122)
        Me.TreeView.TabIndex = 12
        '
        'ViewForm
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(284, 352)
        Me.Controls.Add(Me.TreeView)
        Me.Controls.Add(Me.DateTxt)
        Me.Controls.Add(Me.DateLbl)
        Me.Controls.Add(Me.OpenBtn)
        Me.Controls.Add(Me.DeleteBtn)
        Me.Controls.Add(Me.CloseBtn)
        Me.Controls.Add(Me.DescTxt)
        Me.Controls.Add(Me.CategoryTxt)
        Me.Controls.Add(Me.CreatorTxt)
        Me.Controls.Add(Me.DescLbl)
        Me.Controls.Add(Me.Label2)
        Me.Controls.Add(Me.CreatorLbl)
        Me.Name = "ViewForm"
        Me.Text = "Experiment List"
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents CreatorLbl As System.Windows.Forms.Label
    Friend WithEvents Label2 As System.Windows.Forms.Label
    Friend WithEvents DescLbl As System.Windows.Forms.Label
    Friend WithEvents CreatorTxt As System.Windows.Forms.TextBox
    Friend WithEvents CategoryTxt As System.Windows.Forms.TextBox
    Friend WithEvents DescTxt As System.Windows.Forms.TextBox
    Friend WithEvents CloseBtn As System.Windows.Forms.Button
    Friend WithEvents DeleteBtn As System.Windows.Forms.Button
    Friend WithEvents OpenBtn As System.Windows.Forms.Button
    Friend WithEvents DateLbl As System.Windows.Forms.Label
    Friend WithEvents DateTxt As System.Windows.Forms.DateTimePicker
    Friend WithEvents TreeView As System.Windows.Forms.TreeView
End Class

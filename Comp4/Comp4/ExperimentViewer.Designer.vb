<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class ExperimentViewer
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
        Me.ExpDataView = New System.Windows.Forms.DataGridView()
        Me.TxtDesc = New System.Windows.Forms.TextBox()
        Me.DescLabel = New System.Windows.Forms.Label()
        Me.PassCheckBox = New System.Windows.Forms.CheckBox()
        Me.PassLabel = New System.Windows.Forms.Label()
        Me.TxtPass = New System.Windows.Forms.TextBox()
        Me.ExitBtn = New System.Windows.Forms.Button()
        Me.ExportBtn = New System.Windows.Forms.Button()
        Me.RevertBtn = New System.Windows.Forms.Button()
        Me.RecordDateTime = New System.Windows.Forms.DateTimePicker()
        Me.TimeLabel = New System.Windows.Forms.Label()
        Me.CategoryLabel = New System.Windows.Forms.Label()
        Me.CreatorLabel = New System.Windows.Forms.Label()
        Me.TitleLabel = New System.Windows.Forms.Label()
        Me.TxtCategory = New System.Windows.Forms.TextBox()
        Me.TxtCreator = New System.Windows.Forms.TextBox()
        Me.TxtTitle = New System.Windows.Forms.TextBox()
        Me.ExportFileDialog = New System.Windows.Forms.SaveFileDialog()
        CType(Me.ExpDataView, System.ComponentModel.ISupportInitialize).BeginInit()
        Me.SuspendLayout()
        '
        'ExpDataView
        '
        Me.ExpDataView.AllowUserToAddRows = False
        Me.ExpDataView.AllowUserToDeleteRows = False
        Me.ExpDataView.AllowUserToOrderColumns = True
        Me.ExpDataView.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill
        Me.ExpDataView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize
        Me.ExpDataView.Location = New System.Drawing.Point(12, 12)
        Me.ExpDataView.Name = "ExpDataView"
        Me.ExpDataView.ReadOnly = True
        Me.ExpDataView.RowHeadersVisible = False
        Me.ExpDataView.Size = New System.Drawing.Size(333, 304)
        Me.ExpDataView.TabIndex = 0
        '
        'TxtDesc
        '
        Me.TxtDesc.AcceptsReturn = True
        Me.TxtDesc.Location = New System.Drawing.Point(96, 473)
        Me.TxtDesc.Multiline = True
        Me.TxtDesc.Name = "TxtDesc"
        Me.TxtDesc.ScrollBars = System.Windows.Forms.ScrollBars.Vertical
        Me.TxtDesc.Size = New System.Drawing.Size(248, 107)
        Me.TxtDesc.TabIndex = 34
        '
        'DescLabel
        '
        Me.DescLabel.AutoSize = True
        Me.DescLabel.Location = New System.Drawing.Point(14, 476)
        Me.DescLabel.Name = "DescLabel"
        Me.DescLabel.Size = New System.Drawing.Size(60, 13)
        Me.DescLabel.TabIndex = 33
        Me.DescLabel.Text = "Description"
        '
        'PassCheckBox
        '
        Me.PassCheckBox.AutoSize = True
        Me.PassCheckBox.Location = New System.Drawing.Point(17, 427)
        Me.PassCheckBox.Name = "PassCheckBox"
        Me.PassCheckBox.Size = New System.Drawing.Size(170, 17)
        Me.PassCheckBox.TabIndex = 32
        Me.PassCheckBox.Text = "Password Protect Experiment?"
        Me.PassCheckBox.UseVisualStyleBackColor = True
        '
        'PassLabel
        '
        Me.PassLabel.AutoSize = True
        Me.PassLabel.Location = New System.Drawing.Point(14, 450)
        Me.PassLabel.Name = "PassLabel"
        Me.PassLabel.Size = New System.Drawing.Size(53, 13)
        Me.PassLabel.TabIndex = 31
        Me.PassLabel.Text = "Password"
        '
        'TxtPass
        '
        Me.TxtPass.Location = New System.Drawing.Point(96, 447)
        Me.TxtPass.Name = "TxtPass"
        Me.TxtPass.PasswordChar = Global.Microsoft.VisualBasic.ChrW(42)
        Me.TxtPass.Size = New System.Drawing.Size(249, 20)
        Me.TxtPass.TabIndex = 30
        '
        'ExitBtn
        '
        Me.ExitBtn.Location = New System.Drawing.Point(212, 586)
        Me.ExitBtn.Name = "ExitBtn"
        Me.ExitBtn.Size = New System.Drawing.Size(131, 23)
        Me.ExitBtn.TabIndex = 29
        Me.ExitBtn.Text = "Save and Exit"
        Me.ExitBtn.UseVisualStyleBackColor = True
        '
        'ExportBtn
        '
        Me.ExportBtn.Location = New System.Drawing.Point(12, 586)
        Me.ExportBtn.Name = "ExportBtn"
        Me.ExportBtn.Size = New System.Drawing.Size(104, 23)
        Me.ExportBtn.TabIndex = 28
        Me.ExportBtn.Text = "Export To .CSV"
        Me.ExportBtn.UseVisualStyleBackColor = True
        '
        'RevertBtn
        '
        Me.RevertBtn.Location = New System.Drawing.Point(122, 586)
        Me.RevertBtn.Name = "RevertBtn"
        Me.RevertBtn.Size = New System.Drawing.Size(84, 23)
        Me.RevertBtn.TabIndex = 27
        Me.RevertBtn.Text = "Revert"
        Me.RevertBtn.UseVisualStyleBackColor = True
        '
        'RecordDateTime
        '
        Me.RecordDateTime.Location = New System.Drawing.Point(96, 322)
        Me.RecordDateTime.Name = "RecordDateTime"
        Me.RecordDateTime.Size = New System.Drawing.Size(249, 20)
        Me.RecordDateTime.TabIndex = 26
        Me.RecordDateTime.Value = New Date(2012, 3, 8, 10, 13, 40, 0)
        '
        'TimeLabel
        '
        Me.TimeLabel.AutoSize = True
        Me.TimeLabel.Location = New System.Drawing.Point(12, 328)
        Me.TimeLabel.Name = "TimeLabel"
        Me.TimeLabel.Size = New System.Drawing.Size(68, 13)
        Me.TimeLabel.TabIndex = 25
        Me.TimeLabel.Text = "Record Time"
        '
        'CategoryLabel
        '
        Me.CategoryLabel.AutoSize = True
        Me.CategoryLabel.Location = New System.Drawing.Point(12, 404)
        Me.CategoryLabel.Name = "CategoryLabel"
        Me.CategoryLabel.Size = New System.Drawing.Size(49, 13)
        Me.CategoryLabel.TabIndex = 24
        Me.CategoryLabel.Text = "Category"
        '
        'CreatorLabel
        '
        Me.CreatorLabel.AutoSize = True
        Me.CreatorLabel.Location = New System.Drawing.Point(12, 378)
        Me.CreatorLabel.Name = "CreatorLabel"
        Me.CreatorLabel.Size = New System.Drawing.Size(41, 13)
        Me.CreatorLabel.TabIndex = 23
        Me.CreatorLabel.Text = "Creator"
        '
        'TitleLabel
        '
        Me.TitleLabel.AutoSize = True
        Me.TitleLabel.Location = New System.Drawing.Point(12, 351)
        Me.TitleLabel.Name = "TitleLabel"
        Me.TitleLabel.Size = New System.Drawing.Size(27, 13)
        Me.TitleLabel.TabIndex = 22
        Me.TitleLabel.Text = "Title"
        '
        'TxtCategory
        '
        Me.TxtCategory.Location = New System.Drawing.Point(96, 401)
        Me.TxtCategory.Name = "TxtCategory"
        Me.TxtCategory.Size = New System.Drawing.Size(249, 20)
        Me.TxtCategory.TabIndex = 21
        '
        'TxtCreator
        '
        Me.TxtCreator.Location = New System.Drawing.Point(96, 375)
        Me.TxtCreator.Name = "TxtCreator"
        Me.TxtCreator.Size = New System.Drawing.Size(249, 20)
        Me.TxtCreator.TabIndex = 20
        '
        'TxtTitle
        '
        Me.TxtTitle.Location = New System.Drawing.Point(96, 348)
        Me.TxtTitle.Name = "TxtTitle"
        Me.TxtTitle.Size = New System.Drawing.Size(249, 20)
        Me.TxtTitle.TabIndex = 19
        '
        'ExportFileDialog
        '
        Me.ExportFileDialog.DefaultExt = "csv"
        '
        'ExperimentViewer
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(357, 615)
        Me.Controls.Add(Me.TxtDesc)
        Me.Controls.Add(Me.DescLabel)
        Me.Controls.Add(Me.PassCheckBox)
        Me.Controls.Add(Me.PassLabel)
        Me.Controls.Add(Me.TxtPass)
        Me.Controls.Add(Me.ExitBtn)
        Me.Controls.Add(Me.ExportBtn)
        Me.Controls.Add(Me.RevertBtn)
        Me.Controls.Add(Me.RecordDateTime)
        Me.Controls.Add(Me.TimeLabel)
        Me.Controls.Add(Me.CategoryLabel)
        Me.Controls.Add(Me.CreatorLabel)
        Me.Controls.Add(Me.TitleLabel)
        Me.Controls.Add(Me.TxtCategory)
        Me.Controls.Add(Me.TxtCreator)
        Me.Controls.Add(Me.TxtTitle)
        Me.Controls.Add(Me.ExpDataView)
        Me.Name = "ExperimentViewer"
        Me.Text = "Experiment Viewer - "
        CType(Me.ExpDataView, System.ComponentModel.ISupportInitialize).EndInit()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents ExpDataView As System.Windows.Forms.DataGridView
    Friend WithEvents TxtDesc As System.Windows.Forms.TextBox
    Friend WithEvents DescLabel As System.Windows.Forms.Label
    Friend WithEvents PassCheckBox As System.Windows.Forms.CheckBox
    Friend WithEvents PassLabel As System.Windows.Forms.Label
    Friend WithEvents TxtPass As System.Windows.Forms.TextBox
    Friend WithEvents ExitBtn As System.Windows.Forms.Button
    Friend WithEvents ExportBtn As System.Windows.Forms.Button
    Friend WithEvents RevertBtn As System.Windows.Forms.Button
    Friend WithEvents RecordDateTime As System.Windows.Forms.DateTimePicker
    Friend WithEvents TimeLabel As System.Windows.Forms.Label
    Friend WithEvents CategoryLabel As System.Windows.Forms.Label
    Friend WithEvents CreatorLabel As System.Windows.Forms.Label
    Friend WithEvents TitleLabel As System.Windows.Forms.Label
    Friend WithEvents TxtCategory As System.Windows.Forms.TextBox
    Friend WithEvents TxtCreator As System.Windows.Forms.TextBox
    Friend WithEvents TxtTitle As System.Windows.Forms.TextBox
    Friend WithEvents ExportFileDialog As System.Windows.Forms.SaveFileDialog
End Class

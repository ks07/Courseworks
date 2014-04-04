<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class RecordForm
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
        Me.components = New System.ComponentModel.Container()
        Me.SerialPort = New System.IO.Ports.SerialPort(Me.components)
        Me.TxtTitle = New System.Windows.Forms.TextBox()
        Me.TxtCreator = New System.Windows.Forms.TextBox()
        Me.TxtCategory = New System.Windows.Forms.TextBox()
        Me.StatusStrip = New System.Windows.Forms.StatusStrip()
        Me.ProgBar = New System.Windows.Forms.ToolStripProgressBar()
        Me.StatusLabel = New System.Windows.Forms.ToolStripStatusLabel()
        Me.TitleLabel = New System.Windows.Forms.Label()
        Me.CreatorLabel = New System.Windows.Forms.Label()
        Me.CategoryLabel = New System.Windows.Forms.Label()
        Me.TimeLabel = New System.Windows.Forms.Label()
        Me.RecordDateTime = New System.Windows.Forms.DateTimePicker()
        Me.ApplyBtn = New System.Windows.Forms.Button()
        Me.ConnectBtn = New System.Windows.Forms.Button()
        Me.ExitBtn = New System.Windows.Forms.Button()
        Me.PassLabel = New System.Windows.Forms.Label()
        Me.TxtPass = New System.Windows.Forms.TextBox()
        Me.PassCheckBox = New System.Windows.Forms.CheckBox()
        Me.DescLabel = New System.Windows.Forms.Label()
        Me.TxtDesc = New System.Windows.Forms.TextBox()
        Me.StatusStrip.SuspendLayout()
        Me.SuspendLayout()
        '
        'SerialPort
        '
        Me.SerialPort.PortName = "COM8"
        Me.SerialPort.ReadTimeout = 30000
        Me.SerialPort.WriteTimeout = 30000
        '
        'TxtTitle
        '
        Me.TxtTitle.Enabled = False
        Me.TxtTitle.Location = New System.Drawing.Point(94, 31)
        Me.TxtTitle.MaxLength = 128
        Me.TxtTitle.Name = "TxtTitle"
        Me.TxtTitle.Size = New System.Drawing.Size(247, 20)
        Me.TxtTitle.TabIndex = 0
        '
        'TxtCreator
        '
        Me.TxtCreator.Enabled = False
        Me.TxtCreator.Location = New System.Drawing.Point(94, 58)
        Me.TxtCreator.MaxLength = 64
        Me.TxtCreator.Name = "TxtCreator"
        Me.TxtCreator.Size = New System.Drawing.Size(247, 20)
        Me.TxtCreator.TabIndex = 1
        '
        'TxtCategory
        '
        Me.TxtCategory.Enabled = False
        Me.TxtCategory.Location = New System.Drawing.Point(94, 84)
        Me.TxtCategory.MaxLength = 128
        Me.TxtCategory.Name = "TxtCategory"
        Me.TxtCategory.Size = New System.Drawing.Size(247, 20)
        Me.TxtCategory.TabIndex = 2
        '
        'StatusStrip
        '
        Me.StatusStrip.Items.AddRange(New System.Windows.Forms.ToolStripItem() {Me.ProgBar, Me.StatusLabel})
        Me.StatusStrip.Location = New System.Drawing.Point(0, 295)
        Me.StatusStrip.Name = "StatusStrip"
        Me.StatusStrip.Size = New System.Drawing.Size(355, 22)
        Me.StatusStrip.TabIndex = 3
        Me.StatusStrip.Text = "StatusStrip1"
        '
        'ProgBar
        '
        Me.ProgBar.Name = "ProgBar"
        Me.ProgBar.Size = New System.Drawing.Size(100, 16)
        Me.ProgBar.Style = System.Windows.Forms.ProgressBarStyle.Marquee
        '
        'StatusLabel
        '
        Me.StatusLabel.Name = "StatusLabel"
        Me.StatusLabel.Size = New System.Drawing.Size(48, 17)
        Me.StatusLabel.Text = "Waiting"
        '
        'TitleLabel
        '
        Me.TitleLabel.AutoSize = True
        Me.TitleLabel.Location = New System.Drawing.Point(12, 34)
        Me.TitleLabel.Name = "TitleLabel"
        Me.TitleLabel.Size = New System.Drawing.Size(27, 13)
        Me.TitleLabel.TabIndex = 4
        Me.TitleLabel.Text = "Title"
        '
        'CreatorLabel
        '
        Me.CreatorLabel.AutoSize = True
        Me.CreatorLabel.Location = New System.Drawing.Point(12, 61)
        Me.CreatorLabel.Name = "CreatorLabel"
        Me.CreatorLabel.Size = New System.Drawing.Size(41, 13)
        Me.CreatorLabel.TabIndex = 5
        Me.CreatorLabel.Text = "Creator"
        '
        'CategoryLabel
        '
        Me.CategoryLabel.AutoSize = True
        Me.CategoryLabel.Location = New System.Drawing.Point(12, 87)
        Me.CategoryLabel.Name = "CategoryLabel"
        Me.CategoryLabel.Size = New System.Drawing.Size(49, 13)
        Me.CategoryLabel.TabIndex = 6
        Me.CategoryLabel.Text = "Category"
        '
        'TimeLabel
        '
        Me.TimeLabel.AutoSize = True
        Me.TimeLabel.Location = New System.Drawing.Point(12, 9)
        Me.TimeLabel.Name = "TimeLabel"
        Me.TimeLabel.Size = New System.Drawing.Size(68, 13)
        Me.TimeLabel.TabIndex = 7
        Me.TimeLabel.Text = "Record Time"
        '
        'RecordDateTime
        '
        Me.RecordDateTime.Enabled = False
        Me.RecordDateTime.Location = New System.Drawing.Point(94, 5)
        Me.RecordDateTime.Name = "RecordDateTime"
        Me.RecordDateTime.Size = New System.Drawing.Size(247, 20)
        Me.RecordDateTime.TabIndex = 8
        Me.RecordDateTime.Value = New Date(2012, 3, 8, 10, 13, 40, 0)
        '
        'ApplyBtn
        '
        Me.ApplyBtn.Enabled = False
        Me.ApplyBtn.Location = New System.Drawing.Point(125, 269)
        Me.ApplyBtn.Name = "ApplyBtn"
        Me.ApplyBtn.Size = New System.Drawing.Size(79, 23)
        Me.ApplyBtn.TabIndex = 9
        Me.ApplyBtn.Text = "Apply"
        Me.ApplyBtn.UseVisualStyleBackColor = True
        '
        'ConnectBtn
        '
        Me.ConnectBtn.Location = New System.Drawing.Point(15, 269)
        Me.ConnectBtn.Name = "ConnectBtn"
        Me.ConnectBtn.Size = New System.Drawing.Size(104, 23)
        Me.ConnectBtn.TabIndex = 10
        Me.ConnectBtn.Text = "Begin Recording"
        Me.ConnectBtn.UseVisualStyleBackColor = True
        '
        'ExitBtn
        '
        Me.ExitBtn.Location = New System.Drawing.Point(210, 269)
        Me.ExitBtn.Name = "ExitBtn"
        Me.ExitBtn.Size = New System.Drawing.Size(131, 23)
        Me.ExitBtn.TabIndex = 11
        Me.ExitBtn.Text = "Exit"
        Me.ExitBtn.UseVisualStyleBackColor = True
        '
        'PassLabel
        '
        Me.PassLabel.AutoSize = True
        Me.PassLabel.Location = New System.Drawing.Point(12, 133)
        Me.PassLabel.Name = "PassLabel"
        Me.PassLabel.Size = New System.Drawing.Size(53, 13)
        Me.PassLabel.TabIndex = 14
        Me.PassLabel.Text = "Password"
        '
        'TxtPass
        '
        Me.TxtPass.Enabled = False
        Me.TxtPass.Location = New System.Drawing.Point(94, 130)
        Me.TxtPass.MaxLength = 64
        Me.TxtPass.Name = "TxtPass"
        Me.TxtPass.PasswordChar = Global.Microsoft.VisualBasic.ChrW(42)
        Me.TxtPass.Size = New System.Drawing.Size(247, 20)
        Me.TxtPass.TabIndex = 12
        '
        'PassCheckBox
        '
        Me.PassCheckBox.AutoSize = True
        Me.PassCheckBox.Enabled = False
        Me.PassCheckBox.Location = New System.Drawing.Point(15, 110)
        Me.PassCheckBox.Name = "PassCheckBox"
        Me.PassCheckBox.Size = New System.Drawing.Size(170, 17)
        Me.PassCheckBox.TabIndex = 16
        Me.PassCheckBox.Text = "Password Protect Experiment?"
        Me.PassCheckBox.UseVisualStyleBackColor = True
        '
        'DescLabel
        '
        Me.DescLabel.AutoSize = True
        Me.DescLabel.Location = New System.Drawing.Point(12, 159)
        Me.DescLabel.Name = "DescLabel"
        Me.DescLabel.Size = New System.Drawing.Size(60, 13)
        Me.DescLabel.TabIndex = 17
        Me.DescLabel.Text = "Description"
        '
        'TxtDesc
        '
        Me.TxtDesc.AcceptsReturn = True
        Me.TxtDesc.Enabled = False
        Me.TxtDesc.Location = New System.Drawing.Point(94, 156)
        Me.TxtDesc.MaxLength = 255
        Me.TxtDesc.Multiline = True
        Me.TxtDesc.Name = "TxtDesc"
        Me.TxtDesc.ScrollBars = System.Windows.Forms.ScrollBars.Vertical
        Me.TxtDesc.Size = New System.Drawing.Size(246, 107)
        Me.TxtDesc.TabIndex = 18
        '
        'RecordForm
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(355, 317)
        Me.Controls.Add(Me.TxtDesc)
        Me.Controls.Add(Me.DescLabel)
        Me.Controls.Add(Me.PassCheckBox)
        Me.Controls.Add(Me.PassLabel)
        Me.Controls.Add(Me.TxtPass)
        Me.Controls.Add(Me.ExitBtn)
        Me.Controls.Add(Me.ConnectBtn)
        Me.Controls.Add(Me.ApplyBtn)
        Me.Controls.Add(Me.RecordDateTime)
        Me.Controls.Add(Me.TimeLabel)
        Me.Controls.Add(Me.CategoryLabel)
        Me.Controls.Add(Me.CreatorLabel)
        Me.Controls.Add(Me.TitleLabel)
        Me.Controls.Add(Me.StatusStrip)
        Me.Controls.Add(Me.TxtCategory)
        Me.Controls.Add(Me.TxtCreator)
        Me.Controls.Add(Me.TxtTitle)
        Me.Name = "RecordForm"
        Me.Text = "Record New Experiment"
        Me.StatusStrip.ResumeLayout(False)
        Me.StatusStrip.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Private WithEvents SerialPort As System.IO.Ports.SerialPort
    Private WithEvents TxtTitle As System.Windows.Forms.TextBox
    Private WithEvents TxtCreator As System.Windows.Forms.TextBox
    Private WithEvents TxtCategory As System.Windows.Forms.TextBox
    Private WithEvents StatusStrip As System.Windows.Forms.StatusStrip
    Private WithEvents StatusLabel As System.Windows.Forms.ToolStripStatusLabel
    Private WithEvents ProgBar As System.Windows.Forms.ToolStripProgressBar
    Private WithEvents TitleLabel As System.Windows.Forms.Label
    Private WithEvents CreatorLabel As System.Windows.Forms.Label
    Private WithEvents CategoryLabel As System.Windows.Forms.Label
    Private WithEvents TimeLabel As System.Windows.Forms.Label
    Private WithEvents RecordDateTime As System.Windows.Forms.DateTimePicker
    Private WithEvents ApplyBtn As System.Windows.Forms.Button
    Private WithEvents ConnectBtn As System.Windows.Forms.Button
    Private WithEvents ExitBtn As System.Windows.Forms.Button
    Private WithEvents PassLabel As System.Windows.Forms.Label
    Private WithEvents TxtPass As System.Windows.Forms.TextBox
    Private WithEvents PassCheckBox As System.Windows.Forms.CheckBox
    Private WithEvents DescLabel As System.Windows.Forms.Label
    Private WithEvents TxtDesc As System.Windows.Forms.TextBox
End Class

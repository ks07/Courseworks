<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class MainForm
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
        Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(MainForm))
        Me.RecordBtn = New System.Windows.Forms.Button()
        Me.ViewBtn = New System.Windows.Forms.Button()
        Me.WelcomeLabel = New System.Windows.Forms.Label()
        Me.OptionsBtn = New System.Windows.Forms.Button()
        Me.SuspendLayout()
        '
        'RecordBtn
        '
        Me.RecordBtn.Location = New System.Drawing.Point(12, 110)
        Me.RecordBtn.Name = "RecordBtn"
        Me.RecordBtn.Size = New System.Drawing.Size(100, 59)
        Me.RecordBtn.TabIndex = 0
        Me.RecordBtn.Text = "Record"
        Me.RecordBtn.UseVisualStyleBackColor = True
        '
        'ViewBtn
        '
        Me.ViewBtn.Location = New System.Drawing.Point(234, 110)
        Me.ViewBtn.Name = "ViewBtn"
        Me.ViewBtn.Size = New System.Drawing.Size(93, 59)
        Me.ViewBtn.TabIndex = 1
        Me.ViewBtn.Text = "View"
        Me.ViewBtn.UseVisualStyleBackColor = True
        '
        'WelcomeLabel
        '
        Me.WelcomeLabel.AutoSize = True
        Me.WelcomeLabel.Location = New System.Drawing.Point(13, 13)
        Me.WelcomeLabel.Name = "WelcomeLabel"
        Me.WelcomeLabel.Size = New System.Drawing.Size(279, 52)
        Me.WelcomeLabel.TabIndex = 2
        Me.WelcomeLabel.Text = resources.GetString("WelcomeLabel.Text")
        '
        'OptionsBtn
        '
        Me.OptionsBtn.Location = New System.Drawing.Point(118, 110)
        Me.OptionsBtn.Name = "OptionsBtn"
        Me.OptionsBtn.Size = New System.Drawing.Size(110, 59)
        Me.OptionsBtn.TabIndex = 3
        Me.OptionsBtn.Text = "Options"
        Me.OptionsBtn.UseVisualStyleBackColor = True
        '
        'MainForm
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(339, 181)
        Me.Controls.Add(Me.OptionsBtn)
        Me.Controls.Add(Me.WelcomeLabel)
        Me.Controls.Add(Me.ViewBtn)
        Me.Controls.Add(Me.RecordBtn)
        Me.Name = "MainForm"
        Me.Text = "Serial Data Logger"
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents RecordBtn As System.Windows.Forms.Button
    Friend WithEvents ViewBtn As System.Windows.Forms.Button
    Friend WithEvents WelcomeLabel As System.Windows.Forms.Label
    Friend WithEvents OptionsBtn As System.Windows.Forms.Button

End Class

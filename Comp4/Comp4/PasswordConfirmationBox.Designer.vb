<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class PasswordConfirmationBox
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
        Me.PasswordBox = New System.Windows.Forms.TextBox()
        Me.DialogLabel = New System.Windows.Forms.Label()
        Me.ConfirmButton = New System.Windows.Forms.Button()
        Me.ClearBtn = New System.Windows.Forms.Button()
        Me.SuspendLayout()
        '
        'PasswordBox
        '
        Me.PasswordBox.Location = New System.Drawing.Point(12, 43)
        Me.PasswordBox.Name = "PasswordBox"
        Me.PasswordBox.PasswordChar = Global.Microsoft.VisualBasic.ChrW(42)
        Me.PasswordBox.Size = New System.Drawing.Size(308, 20)
        Me.PasswordBox.TabIndex = 0
        '
        'DialogLabel
        '
        Me.DialogLabel.AutoSize = True
        Me.DialogLabel.Location = New System.Drawing.Point(12, 9)
        Me.DialogLabel.Name = "DialogLabel"
        Me.DialogLabel.Size = New System.Drawing.Size(308, 26)
        Me.DialogLabel.TabIndex = 1
        Me.DialogLabel.Text = "Please re-type the password for this experiment. Press the Clear " & Global.Microsoft.VisualBasic.ChrW(13) & Global.Microsoft.VisualBasic.ChrW(10) & "Password butto" & _
            "n to save this experiment without a password."
        '
        'ConfirmButton
        '
        Me.ConfirmButton.Enabled = False
        Me.ConfirmButton.Location = New System.Drawing.Point(327, 38)
        Me.ConfirmButton.Name = "ConfirmButton"
        Me.ConfirmButton.Size = New System.Drawing.Size(105, 23)
        Me.ConfirmButton.TabIndex = 2
        Me.ConfirmButton.Text = "Confirm"
        Me.ConfirmButton.UseVisualStyleBackColor = True
        '
        'ClearBtn
        '
        Me.ClearBtn.Location = New System.Drawing.Point(327, 9)
        Me.ClearBtn.Name = "ClearBtn"
        Me.ClearBtn.Size = New System.Drawing.Size(105, 23)
        Me.ClearBtn.TabIndex = 3
        Me.ClearBtn.Text = "Clear Password"
        Me.ClearBtn.UseVisualStyleBackColor = True
        '
        'PasswordConfirmationBox
        '
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(444, 72)
        Me.Controls.Add(Me.ClearBtn)
        Me.Controls.Add(Me.ConfirmButton)
        Me.Controls.Add(Me.DialogLabel)
        Me.Controls.Add(Me.PasswordBox)
        Me.Name = "PasswordConfirmationBox"
        Me.Text = "Password Confirmation"
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub
    Friend WithEvents PasswordBox As System.Windows.Forms.TextBox
    Friend WithEvents DialogLabel As System.Windows.Forms.Label
    Friend WithEvents ConfirmButton As System.Windows.Forms.Button
    Friend WithEvents ClearBtn As System.Windows.Forms.Button
End Class

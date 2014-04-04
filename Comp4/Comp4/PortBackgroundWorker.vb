Public Class PortBackgroundWorker
    Inherits System.ComponentModel.BackgroundWorker

    Public Overloads Sub ReportProgress(ByVal percentProgress As Integer, ByVal progressText As String)
        MyBase.ReportProgress(percentProgress, New SerialWorkerState(progressText))
    End Sub

    Friend Class SerialWorkerState
        Public ReadOnly ProgressText As String

        Public Sub New(ByVal ptext As String)
            Me.ProgressText = ptext
        End Sub
    End Class
End Class

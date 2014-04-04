Public Class DummyParser
    Inherits DataParser
    Private ex As Experiment
    Private compStatus As CompletionStatus

    ' Completed operation.
    Public Sub New(ByRef exp As Experiment)
        Me.ex = exp
        Me.compStatus = CompletionStatus.COMPLETE
    End Sub

    ' Incomplete operation.
    Public Sub New(ByVal failureStatus As CompletionStatus)
        ' If this constructor is called, we don't have any experiment data to supply to the parent object.
        ' To avoid NullReferenceExceptions, the status provided here must be a failure status (integer value of <0).
        If CInt(failureStatus) < 0 Then
            Me.compStatus = failureStatus
        Else
            Throw New ArgumentException("Attempted to set a finished state without supplying experiment data.")
        End If
    End Sub

    ' Tell the parent object that it should no longer try to read from the serial port.
    Public Overrides Function getCompletionStatus() As CompletionStatus
        Return Me.compStatus
    End Function

    Public Overrides Function read() As DataParser
        ' Once we reach this stage, we are no longer looking for data from the serial port, which should be closed.
        ' This method should not be called, so throw an exception.
        Throw New ConstraintException("Attempted to read from disconnected serial port.")
        Return Me
    End Function

    Public Overrides Function getExperiment() As Experiment
        Return ex
    End Function
End Class

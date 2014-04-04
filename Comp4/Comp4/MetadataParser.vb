Imports System.IO.Ports.SerialPort

Public Class MetadataParser
    Inherits DataParser
    Private port As IO.Ports.SerialPort
    Private parentWorker As PortBackgroundWorker

    Public Sub New(ByRef serialPort As IO.Ports.SerialPort, ByRef parent As System.ComponentModel.BackgroundWorker)
        serialPort.NewLine = DataParser.RS
        Me.port = serialPort
        Me.parentWorker = parent
    End Sub

    Public Overrides Function getCompletionStatus() As CompletionStatus
        Return CompletionStatus.PENDING
    End Function

    Public Overrides Function read() As DataParser
        Dim ex As Experiment
        Dim hasMetadata As Boolean = False
        Dim tmpLine As String
        ' Read the metadata confirmation line
        tmpLine = Me.port.ReadLine()
        ' Check if contains (ack)
        hasMetadata = tmpLine.Contains(DataParser.ACK)

        ' Check if the user has cancelled the operation, end the record operations if so.
        ' We must distribute these checks throughout the code, making sure that as few expensive
        ' operations separate them as possible to ensure a fast response to user input.
        If parentWorker.CancellationPending Then
            Return New DummyParser(CompletionStatus.CANCELLED)
        End If

        If hasMetadata Then
            Dim name, creator, category As String

            ' Update the status bar to show the user the program is not hung.
            Me.parentWorker.ReportProgress(10, "Connection established.")

            ' Title, Creator, Category
            ' The next separator should be US
            Me.port.NewLine = DataParser.US
            ' TODO: Sanitise names with a regex.
            name = Me.port.ReadLine()
            creator = Me.port.ReadLine()

            ' Cancellation check.
            If parentWorker.CancellationPending Then
                Return New DummyParser(CompletionStatus.CANCELLED)
            End If

            ' Final field of the record, so switch to RS
            Me.port.NewLine = DataParser.RS
            category = Me.port.ReadLine()

            ex = New Experiment(name, creator, category, "", Date.Now)
        Else
            ex = New Experiment()
        End If

        ' Cancellation check.
        If parentWorker.CancellationPending Then
            Return New DummyParser(CompletionStatus.CANCELLED)
        End If

        Return New DefinitionsParser(Me.port, ex, Me.parentWorker)
    End Function

    Public Overrides Function getExperiment() As Experiment
        Return Nothing
    End Function
End Class

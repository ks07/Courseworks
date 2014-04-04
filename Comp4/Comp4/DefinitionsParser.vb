Public Class DefinitionsParser
    Inherits DataParser
    Private ex As Experiment
    Private port As System.IO.Ports.SerialPort
    Private parentWorker As PortBackgroundWorker

    Public Sub New(ByRef serialPort As System.IO.Ports.SerialPort, ByRef exp As Experiment, ByRef parent As PortBackgroundWorker)
        Me.ex = exp
        Me.port = serialPort
        Me.parentWorker = parent
    End Sub

    Public Overrides Function getCompletionStatus() As CompletionStatus
        Return CompletionStatus.PENDING
    End Function

    Public Overrides Function read() As DataParser
        Dim tmpLine, name As String
        Dim fields As New List(Of Field)
        Dim tmpField As Field
        Dim type As Field.FieldType

        ' The following character should be a group separator
        tmpLine = intToChar(Me.port.ReadChar())
        CheckAssertion(tmpLine.Equals(DataParser.GS), "Expected GS, received " & tmpLine)

        ' Cancellation check.
        If parentWorker.CancellationPending Then
            Return New DummyParser(CompletionStatus.CANCELLED)
        End If

        ' Readline needs to look for US to collect 
        Me.port.NewLine = DataParser.US

        ' Get a single character and load into tmpLine.
        tmpLine = intToChar(Me.port.ReadChar())

        ' Cancellation check.
        If parentWorker.CancellationPending Then
            Return New DummyParser(CompletionStatus.CANCELLED)
        End If

        ' Loop through definitions until we reach the next GS, signifying the end of fields.
        Do Until tmpLine.Equals(DataParser.GS)
            ' We have read one character ahead, so if it was not GS, it is the first character of the name.
            name = tmpLine & Me.port.ReadLine()
            type = Field.ToFieldType(Me.port.ReadByte())
            tmpField = New Field(name, type)

            ' Cancellation check.
            If parentWorker.CancellationPending Then
                Return New DummyParser(CompletionStatus.CANCELLED)
            End If

            ' This list MUST keep insertion order - we need to assure this!
            fields.Add(tmpField)

            tmpLine = intToChar(Me.port.ReadChar())

            ' This character should either be RS or GS. If GS, we exit the loop. If RS, we take the next char.
            If tmpLine.Equals(DataParser.RS) Then
                tmpLine = intToChar(Me.port.ReadChar())
            End If

            ' Cancellation check.
            If parentWorker.CancellationPending Then
                Return New DummyParser(CompletionStatus.CANCELLED)
            End If
        Loop

        CheckAssertion(fields.Count > 0, "Received no field definitions from serial device!")

        ' Update status of form.
        Me.parentWorker.ReportProgress(30, "Experiment ready. Waiting for data.")

        Dim fieldDefs As New FieldDefinitions()
        fieldDefs.registerFields(fields.ToArray())
        Me.ex.FieldDefinitions = fieldDefs

        ' Cancellation check.
        If parentWorker.CancellationPending Then
            Return New DummyParser(CompletionStatus.CANCELLED)
        End If

        Return New BodyParser(Me.port, Me.ex, Me.parentWorker)
    End Function

    Public Overrides Function getExperiment() As Experiment
        Return ex
    End Function
End Class

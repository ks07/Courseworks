Public Class BodyParser
    Inherits DataParser
    Private ex As Experiment
    Private port As System.IO.Ports.SerialPort
    Private previousAvailable As Boolean
    Private previousByte As Integer
    Private parentWorker As PortBackgroundWorker

    Public Sub New(ByRef serialPort As System.IO.Ports.SerialPort, ByRef exp As Experiment, ByRef parent As PortBackgroundWorker)
        Me.ex = exp
        Me.port = serialPort
        Me.parentWorker = parent
    End Sub

    Public Overrides Function getCompletionStatus() As CompletionStatus
        Return CompletionStatus.PENDING
    End Function

    Public Overrides Function getExperiment() As Experiment
        Return ex
    End Function

    Private Function readByte() As Integer
        If Me.previousAvailable Then
            Me.previousAvailable = False
            Return Me.previousByte
        Else
            Return Me.port.ReadByte()
        End If
    End Function

    Private Function readLine() As String
        Dim ret As String = Me.port.ReadLine()

        If Me.previousAvailable Then
            Me.previousAvailable = False
            ret = intToChar(Me.previousByte).ToString() & ret
        End If

        Return ret
    End Function

    Public Overrides Function read() As DataParser
        Dim endBody As Boolean = False
        Dim count As Integer = 0
        Dim dt As DataTable = Me.ex.ExperimentData
        Dim tmpRow As DataRow = dt.NewRow()
        ex.FieldDefinitions.nextRow()

        ' The following bytes should follow the pattern defined by the experiment's field definitions
        ' Loop through reads until we reach the end of stream
        Do
            ' Cancellation check.
            If parentWorker.CancellationPending Then
                Return New DummyParser(CompletionStatus.CANCELLED)
            End If

            If ex.FieldDefinitions.hasNext() Then
                Select Case ex.FieldDefinitions.getNext().Type
                    Case Field.FieldType.UINT
                        Dim MSB, LSB As Byte
                        MSB = Me.readByte()
                        LSB = Me.port.ReadByte()

                        Dim value As UShort = DataParser.joinBytesUnsigned(MSB, LSB)
                        tmpRow.Item(count) = value

                        Dim tmpLine As String = intToChar(Me.port.ReadChar())
                        CheckAssertion(tmpLine.Equals(DataParser.RS) Or tmpLine.Equals(DataParser.US), "Received unexpected character in data fields!")
                    Case Field.FieldType.INT
                        Dim MSB, LSB As Byte
                        MSB = Me.readByte()
                        LSB = Me.port.ReadByte()

                        Dim value As Short = DataParser.joinBytesSigned(MSB, LSB)
                        tmpRow.Item(count) = value

                        Dim tmpLine As String = intToChar(Me.port.ReadChar())
                        CheckAssertion(tmpLine.Equals(DataParser.RS) Or tmpLine.Equals(DataParser.US), "Received unexpected character in data fields!")
                    Case Field.FieldType.TEXT
                        'If we're on the final field, delimeter is RS, else US
                        If ex.FieldDefinitions.hasNext() Then
                            Me.port.NewLine = DataParser.US
                        Else
                            Me.port.NewLine = DataParser.RS
                        End If

                        ' We don't need to pull in the next byte, as reading the line will consume it.
                        Dim value As String = Me.readLine()
                        tmpRow.Item(count) = value
                    Case Field.FieldType.CHR
                        Dim value As Char = intToChar(Me.readByte())
                        tmpRow.Item(count) = value

                        Dim tmpLine As String = intToChar(Me.port.ReadChar())
                        CheckAssertion(tmpLine.Equals(DataParser.RS) Or tmpLine.Equals(DataParser.US), "Received unexpected character in data fields!")
                    Case Field.FieldType.BOOL
                        Dim value As Boolean = intToBool(Me.readByte())
                        tmpRow.Item(count) = value

                        Dim tmpLine As String = intToChar(Me.port.ReadChar())
                        CheckAssertion(tmpLine.Equals(DataParser.RS) Or tmpLine.Equals(DataParser.US), "Received unexpected character in data fields!")
                End Select

                count += 1
            Else
                ' Row is complete, add it to the table and get a new row.
                dt.Rows.Add(tmpRow)
                tmpRow = dt.NewRow()

                ex.FieldDefinitions.nextRow()
                count = 0

                Me.parentWorker.ReportProgress(50, "Recording data...")

                Me.previousByte = Me.port.ReadByte()
                Dim tmpLine As String = intToChar(Me.previousByte)

                If tmpLine.Equals(DataParser.EOT) Then
                    endBody = True
                Else
                    Me.previousAvailable = True
                End If
            End If
        Loop Until endBody

        ' Save the updated datatable
        Me.ex.ExperimentData = dt

        ' Close the serial port
        Me.port.Close()

        ' We must return an instance of DataParser. We return a dummy object that only holds the finished experiment.
        Return New DummyParser(Me.ex)
    End Function
End Class

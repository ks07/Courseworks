Public MustInherit Class DataParser
    ''' <summary>   The ASCII Group Separator character. </summary>
    Protected Const GS As String = Chr(&H1D)
    ''' <summary>   The ASCII Record Separator character. </summary>
    Protected Const RS As String = Chr(&H1E)
    ''' <summary>   The ASCII Unit Separator character. </summary>
    Protected Const US As String = Chr(&H1F)
    ''' <summary>   The ASCII Acknowledgement character. </summary>
    Protected Const ACK As String = Chr(&H6)
    ''' <summary>   The ASCII End Of Text character. </summary>
    Protected Const EOT As String = Chr(&H3)

    '''=================================================================================================
    ''' <summary>   Reads the next arbitrary section of the transmission from the serial port. </summary>
    '''
    ''' <returns>   A new dataparser that reflects the current state of transmission. </returns>
    '''=================================================================================================

    Public MustOverride Function read() As DataParser

    '''=================================================================================================
    ''' <summary>   Gets the completion status. </summary>
    '''
    ''' <returns>   The completion status. </returns>
    '''=================================================================================================

    Public MustOverride Function getCompletionStatus() As CompletionStatus

    '''=================================================================================================
    ''' <summary>   Gets the experiment. </summary>
    '''
    ''' <returns>   The experiment. </returns>
    '''=================================================================================================

    Public MustOverride Function getExperiment() As Experiment

    '''=================================================================================================
    ''' <summary>   Converts an integer value to a character. </summary>
    '''
    ''' <param name="code">  The ASCII character code to convert. </param>
    '''
    ''' <returns>   The character value of the given character code. </returns>
    '''=================================================================================================

    Protected Function intToChar(ByVal code As Integer) As Char
        Return Chr(code)
    End Function

    '''=================================================================================================
    ''' <summary>   Converts an integer to a boolean. </summary>
    '''
    ''' <param name="int">  The integer. </param>
    '''
    ''' <returns>   True if the integer is non-zero, otherwise false. </returns>
    '''=================================================================================================

    Protected Function intToBool(ByVal int As Integer) As Boolean
        Return int <> 0
    End Function

    '''=================================================================================================
    ''' <summary>   Check an assertion and throw an exception if it fails. </summary>
    '''
    ''' <exception cref="Exception">    Thrown when the assertion fails. </exception>
    '''
    ''' <param name="expression">   The expression that must be true. </param>
    ''' <param name="errorMessage"> Message describing the error. </param>
    '''=================================================================================================

    Protected Sub CheckAssertion(ByVal expression As Boolean, ByVal errorMessage As String)
        If Not expression Then
            Throw New Exception(errorMessage)
        End If
    End Sub

    '''=================================================================================================
    ''' <summary>   Join bytes to make an unsigned 16-bit integer. </summary>
    '''
    ''' <param name="mostSignificant">  The most significant byte. </param>
    ''' <param name="leastSignificant"> The least significant byte. </param>
    '''
    ''' <returns> The unsigned integer resulting from the join. </returns>
    '''=================================================================================================

    Protected Shared Function joinBytesUnsigned(ByVal mostSignificant As Byte, ByVal leastSignificant As Byte) As UShort
        Dim ret As UShort

        ' Use a bitshift operator to move the binary digits 8 to the left.
        ' We must explicitly cast the most significant byte to avoid issues with overflows.
        ret = CUShort(mostSignificant) << 8

        ' Add the lower byte to the shifted number normally.
        ' The lower 8 bits of the new number are all 0 at this point, so the addition effectively
        ' switches these 8 bits with the 8 bits we are adding (no carrying will happen).
        ret += leastSignificant

        Return ret
    End Function

    '''=================================================================================================
    ''' <summary>   Join bytes to make a signed 16-bit integer. </summary>
    '''
    ''' <param name="mostSignificant">  The most significant byte. </param>
    ''' <param name="leastSignificant"> The least significant byte. </param>
    '''
    ''' <returns> The signed integer resulting from the join. </returns>
    '''=================================================================================================

    Protected Shared Function joinBytesSigned(ByVal mostSignificant As Byte, ByVal leastSignificant As Byte) As Short
        Dim ret As Short

        ' Use a bitshift operator to move the binary digits 8 to the left.
        ' We must explicitly cast the most significant byte to avoid issues with overflows.
        ret = CShort(mostSignificant) << 8

        ' Add the lower byte to the shifted number normally.
        ' The lower 8 bits of the new number are all 0 at this point, so the addition effectively
        ' switches these 8 bits with the 8 bits we are adding (no carrying will happen).
        ret += leastSignificant

        Return ret
    End Function

    '''=================================================================================================
    ''' <summary>
    '''     Values that show the status of the current operation. 0 shows a pending result.
    '''     Negative values represent failure states, positive values show successful outcomes.
    ''' </summary>
    ''' =================================================================================================

    Public Enum CompletionStatus As SByte
        CANCELLED = -1
        PENDING = 0
        COMPLETE = 1
    End Enum

End Class

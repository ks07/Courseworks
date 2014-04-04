Public Class Field
    Private header As String
    Private dataType As FieldType
    Private order As Integer

    Public Sub New(ByVal name As String, ByVal type As FieldType)
        Me.Name = name
        Me.Type = type
    End Sub

    Public Property Name() As String
        Get
            Return header
        End Get
        Set(ByVal value As String)
            header = value
        End Set
    End Property

    Public Property Type() As FieldType
        Get
            Return dataType
        End Get
        Set(ByVal value As FieldType)
            dataType = value
        End Set
    End Property

    Public Property Count() As Integer
        Get
            Return Me.order
        End Get
        Set(ByVal value As Integer)
            Me.order = value
        End Set
    End Property

    Public Shared Function ToFieldType(ByVal index As Integer) As FieldType
        Return CType(index, FieldType)
    End Function

    Public Shared Function ToFieldType(ByVal name As String) As FieldType
        Dim ret As FieldType
        ret = [Enum].TryParse(name, ret)

        Return ret
    End Function

    Public Enum FieldType As Byte
        TEXT = 0
        UINT = 1
        INT = 2
        BOOL = 3
        CHR = 4
    End Enum
End Class

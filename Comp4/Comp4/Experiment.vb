Imports System.Collections.ObjectModel
Imports System.IO

Public Class Experiment
    Private fieldDefs As FieldDefinitions
    Private index As Integer = -1
    Private title, owner, catName, desc As String
    Private passhash As Passwords.HashedPassword
    Private hasPassword As Boolean = False
    Private datetime As Date
    Private dataStore As DataTable

    ' New experiment, no metadata was received.
    Public Sub New()
        Me.title = "Unnamed Experiment"
        Me.owner = "Unnamed User"
        Me.catName = ""
        Me.desc = "New experiment"
        Me.datetime = Date.Now()
    End Sub

    ' We don't have an index - this is a new experiment that has yet to be saved.
    Public Sub New(ByVal title As String, ByVal creator As String, ByVal category As String, ByVal description As String, ByVal datetime As Date)
        Me.title = title
        Me.owner = creator
        Me.catName = category
        Me.desc = description
        Me.datetime = datetime
    End Sub

    Public Sub New(ByVal id As Integer, ByVal title As String, ByVal creator As String, ByVal category As String, ByVal description As String, ByVal datetime As Date)
        Me.index = id
        Me.title = title
        Me.owner = creator
        Me.catName = category
        Me.desc = description
        Me.datetime = datetime
    End Sub

    Public Property Name() As String
        Get
            Return title
        End Get
        Set(ByVal value As String)
            title = value
        End Set
    End Property

    Public Property Creator() As String
        Get
            Return owner
        End Get
        Set(ByVal value As String)
            owner = value
        End Set
    End Property

    Public Property Category() As String
        Get
            Return catName
        End Get
        Set(ByVal value As String)
            catName = value
        End Set
    End Property

    Public Property Description() As String
        Get
            Return desc
        End Get
        Set(ByVal value As String)
            desc = value
        End Set
    End Property

    Public Property CreationDate() As Date
        Get
            Return datetime
        End Get
        Set(ByVal value As Date)
            datetime = value
        End Set
    End Property

    Public Property ExperimentData() As DataTable
        Get
            Return Me.dataStore
        End Get
        Set(ByVal value As DataTable)
            Me.dataStore = value
        End Set
    End Property

    Public ReadOnly Property ID() As Integer
        Get
            Return Me.index
        End Get
    End Property

    Public Property FieldDefinitions() As FieldDefinitions
        Get
            Return Me.fieldDefs
        End Get
        Set(ByVal fieldDefs As FieldDefinitions)
            Me.fieldDefs = fieldDefs
            Me.dataStore = New DataTable(Me.title)
            Dim cols As DataColumnCollection = Me.dataStore.Columns

            For Each subField As Field In fieldDefs.getFieldList
                Dim tempCol As DataColumn

                Select Case subField.Type
                    Case Field.FieldType.TEXT, Field.FieldType.CHR
                        tempCol = New DataColumn(subField.Name, System.Type.GetType("System.String"))
                    Case Field.FieldType.INT, Field.FieldType.UINT, Field.FieldType.BOOL
                        tempCol = New DataColumn(subField.Name, System.Type.GetType("System.Int64"))
                        'Case FieldDefinitions.FieldType.BIN
                        'tempCol = New DataColumn("zoo", System.Type.GetType("System.Byte[]"))
                    Case Else
                        Continue For
                End Select

                Me.dataStore.Columns.Add(tempCol)
            Next
        End Set
    End Property

    Public Property PasswordProtected As Boolean
        Get
            Return Me.hasPassword
        End Get
        Set(ByVal enablePassword As Boolean)
            If enablePassword Then
                If IsNothing(Me.passhash) Then
                    Me.hasPassword = False
                    Throw New InvalidOperationException("Cannot enable password protection without setting a password first.")
                Else
                    Me.hasPassword = True
                End If
            Else
                Me.passhash = Nothing
                Me.hasPassword = False
            End If
        End Set
    End Property

    Public Property Password As Passwords.HashedPassword
        Get
            Return Me.passhash
        End Get
        Set(ByVal value As Passwords.HashedPassword)
            Me.passhash = value
            Me.hasPassword = True
        End Set
    End Property

    Public Sub exportAsCSV(ByVal filename As String)
        ' (Row, Field)
        Dim tableArray(Me.dataStore.Rows.Count, Me.dataStore.Columns.Count - 1) As String
        Dim count As Integer = 0

        For Each col As DataColumn In Me.dataStore.Columns
            tableArray(0, count) = col.ColumnName
            count += 1
        Next

        count = 1

        For Each row As DataRow In Me.dataStore.Rows
            Dim fldCount As Integer = 0
            For Each item As Object In row.ItemArray
                tableArray(count, fldCount) = CStr(item)
                fldCount += 1
            Next

            count += 1
        Next

        writeCSV(tableArray, filename, False)
    End Sub

    ' Generic CSV writing subroutine. Could be used elsewhere if needed.
    Private Shared Sub writeCSV(ByVal inputarray(,) As String, ByVal filename As String, ByVal append As Boolean)
        Dim fields, rows, i, j As Integer
        Dim filewriter As New StreamWriter(filename, append)

        'Want our subroutine to be usable elsewhere with variable array sizes
        rows = inputarray.GetLength(0)
        fields = inputarray.GetLength(1)

        'Debug:
        Debug.WriteLine("Fields (columns): " & fields)
        Debug.WriteLine("Rows: " & rows)

        'Minus 1 because arrays begin at 0
        For i = 0 To rows - 1
            For j = 0 To fields - 1
                filewriter.Write(inputarray(i, j))

                'Lines in a CSV file should not have trailing commas!
                If Not j = fields - 1 Then
                    filewriter.Write(",")
                Else
                    filewriter.WriteLine()
                End If
            Next
        Next

        'Close the file so it is written to the disk.
        filewriter.Close()

    End Sub
End Class
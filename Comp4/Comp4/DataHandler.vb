Imports System.Data.OleDb
Imports Comp4.Field

Public Class DataHandler
    Private dbConnStr As String

    Private db As New ADOX.Catalog
    Private dbADOConn As New ADODB.Connection
    ' Define the data adapters as WithEvents - this allows us to use the Handles keywords to easily match events with their handlers.
    Private WithEvents exAdap, catAdap, passAdap, fieldAdap, rcrdAdap, txtAdap, intAdap, blobAdap As OleDbDataAdapter
    Private exCmd, catCmd, passCmd, fieldCmd, rcrdCmd, txtCmd, intCmd, blobCmd As OleDbCommandBuilder
    Private dbConnection As OleDbConnection

    Private dbData As DataSet

    Public Function getExperimentList() As List(Of Experiment)
        Dim ret As New List(Of Experiment)(Me.dbData.Tables.Item("Experiments").Rows.Count)
        Dim tempEx As Experiment

        For Each row As DataRow In Me.dbData.Tables.Item("Experiments").Rows
            Dim catName As String

            If IsDBNull(row.Item("catID")) Then
                catName = ""
            Else
                catName = row.GetParentRow("CatEx").Item("name")
            End If

            tempEx = New Experiment(row.Item("expID"), row.Item("name"), row.Item("owner"), catName, row.Item("notes"), row.Item("dateCreated"))

            If Not IsDBNull(row.Item("passID")) Then
                Dim hPass As New Passwords.HashedPassword
                hPass.passwordHash = row.GetParentRow("PassEx").Item("passHash")
                hPass.passwordSalt = row.GetParentRow("PassEx").Item("passSalt")

                tempEx.Password = hPass
            End If

            ret.Add(tempEx)
        Next

        Return ret
    End Function

    Private Sub fillExperimentDefinitions(ByRef ex As Experiment)
        Dim fieldDefs As New FieldDefinitions
        Dim tmpType As FieldType
        Dim count As Integer = 0

        Dim definitionRows() As DataRow = Me.dbData.Tables.Item("ExperimentFields").Select("expID = " & ex.ID.ToString())

        If Not definitionRows.Length > 0 Then
            Throw New Exception("No fields stored in database for experiment ID " & ex.ID.ToString())
        End If

        Dim fieldArray(definitionRows.Length - 1) As Field

        For Each row As DataRow In definitionRows
            tmpType = Field.ToFieldType(row.Item("dataType"))
            fieldArray(count) = New Field(row.Item("fieldHeader"), tmpType)
            count += 1
        Next

        fieldDefs.registerFields(fieldArray)
        ex.FieldDefinitions = fieldDefs
    End Sub

    Public Sub saveNewExperiment(ByRef ex As Experiment)
        Dim expRow, catRow, fldRow As DataRow

        ' Add the definition to the experiments table.
        expRow = Me.dbData.Tables.Item("Experiments").NewRow()
        expRow.Item("name") = ex.Name
        expRow.Item("owner") = ex.Creator
        expRow.Item("notes") = ex.Description
        expRow.Item("dateCreated") = ex.CreationDate

        ' Parent tables must be added first so that we know their unique key.
        If Not doesCategoryExist(ex.Category) Then
            catRow = Me.dbData.Tables.Item("Categories").NewRow()
            catRow.Item("name") = ex.Category
            Me.dbData.Tables.Item("Categories").Rows.Add(catRow)
            Me.catAdap.Update(Me.dbData, "Categories")
        End If

        If ex.PasswordProtected Then
            Dim passRow As DataRow = Me.dbData.Tables.Item("Passwords").NewRow()
            passRow.Item("passHash") = ex.Password.passwordHash
            passRow.Item("passSalt") = ex.Password.passwordSalt
            Me.dbData.Tables.Item("Passwords").Rows.Add(passRow)
            Me.passAdap.Update(Me.dbData, "Passwords")
            expRow.SetParentRow(passRow, Me.dbData.Relations("PassEx"))
        End If

        catRow = Me.dbData.Tables.Item("Categories").Select("name = '" & ex.Category & "'")(0)
        expRow.SetParentRow(catRow, Me.dbData.Relations("CatEx"))

        ' Save the experiment.
        Me.dbData.Tables.Item("Experiments").Rows.Add(expRow)
        Me.exAdap.Update(Me.dbData, "Experiments")

        ' Now we can begin saving all the child rows of the experiment.
        Dim fldCount As Integer = 1
        For Each fld As Field In ex.FieldDefinitions.getFieldList
            fldRow = Me.dbData.Tables.Item("ExperimentFields").NewRow()
            ' Manually set the count field for each row. Order must be preserved.
            fldRow.Item("fieldCount") = fldCount
            fldRow.Item("fieldHeader") = fld.Name
            fldRow.Item("dataType") = CInt(fld.Type)

            fldRow.SetParentRow(expRow, Me.dbData.Relations("ExExfld"))
            Me.dbData.Tables.Item("ExperimentFields").Rows.Add(fldRow)

            fldCount += 1
        Next
        Me.fieldAdap.Update(Me.dbData, "ExperimentFields")

        ' Do saving of rows of data in a seperate method for better readability.
        For Each row As DataRow In ex.ExperimentData.Rows
            Me.addDataRow(ex.FieldDefinitions, row, expRow)
        Next

        Me.dbConnection.Close()
    End Sub

    Public Sub saveModifiedExperimentMetadata(ByRef ex As Experiment, ByVal passwordChanged As Boolean)
        ' It is not necessary to update recorded data, as the user cannot modify it.
        Dim tmpRows(), expRow, catRow, passRow As DataRow
        tmpRows = Me.dbData.Tables.Item("Experiments").Select("expID = " & ex.ID.ToString())

        If tmpRows.Length > 0 Then
            expRow = tmpRows(0)

            ' Set the fields to their new values.
            expRow.Item("name") = ex.Name
            expRow.Item("owner") = ex.Creator
            expRow.Item("notes") = ex.Description
            expRow.Item("dateCreated") = ex.CreationDate

            ' Check if the category we are now set to exists.
            If Not Me.doesCategoryExist(ex.Category) Then
                catRow = Me.dbData.Tables.Item("Categories").NewRow()
                catRow.Item("name") = ex.Category
                Me.dbData.Tables.Item("Categories").Rows.Add(catRow)
                Me.catAdap.Update(Me.dbData, "Categories")
            End If

            ' We are told whether the password has been modified or not.
            If ex.PasswordProtected And passwordChanged Then
                passRow = Me.dbData.Tables.Item("Passwords").NewRow()
                passRow.Item("passHash") = ex.Password.passwordHash
                passRow.Item("passSalt") = ex.Password.passwordSalt
                Me.dbData.Tables.Item("Passwords").Rows.Add(passRow)
                Me.passAdap.Update(Me.dbData, "Passwords")
                expRow.SetParentRow(passRow, Me.dbData.Relations("PassEx"))
            ElseIf Not ex.PasswordProtected Then
                expRow.Item("passID") = DBNull.Value
            End If

            ' Update the category.
            catRow = Me.dbData.Tables.Item("Categories").Select("name = '" & ex.Category & "'")(0)
            expRow.SetParentRow(catRow, Me.dbData.Relations("CatEx"))

            ' Save the experiment.
            'expRow.AcceptChanges()
            'Me.dbData.Tables.Item("Experiments").Rows.
            Me.exAdap.Update(Me.dbData, "Experiments")
        End If

    End Sub

    Private Sub addDataRow(ByRef fields As FieldDefinitions, ByVal dr As DataRow, ByRef experimentRow As DataRow)
        Dim newRow As DataRow
        fields.nextRow()

        For Each item As Object In dr.ItemArray
            ' All items in record row are automatically set, so just create new.
            Dim recordRow As DataRow = Me.dbData.Tables.Item("ExperimentRecords").NewRow()
            recordRow.SetParentRow(experimentRow, Me.dbData.Relations("ExExrec"))
            Me.dbData.Tables.Item("ExperimentRecords").Rows.Add(recordRow)
            Me.rcrdAdap.Update(Me.dbData, "ExperimentRecords")

            ' We don't check hasNext(), as this should always be the case (it will have been checked while recording).
            Select Case fields.getNext().Type
                Case FieldType.TEXT, FieldType.CHR
                    newRow = Me.dbData.Tables.Item("Texts").NewRow()
                    newRow.Item("storedValue") = CStr(item)
                    newRow.SetParentRow(recordRow, Me.dbData.Relations("ExrecTxts"))
                    Me.dbData.Tables.Item("Texts").Rows.Add(newRow)
                    Me.txtAdap.Update(Me.dbData, "Texts")
                Case FieldType.INT, FieldType.UINT, FieldType.BOOL
                    newRow = Me.dbData.Tables.Item("Integers").NewRow()
                    newRow.Item("storedValue") = CInt(item)
                    newRow.SetParentRow(recordRow, Me.dbData.Relations("ExrecInts"))
                    Me.dbData.Tables.Item("Integers").Rows.Add(newRow)
                    Me.intAdap.Update(Me.dbData, "Integers")
            End Select
        Next
    End Sub

    Private Function doesCategoryExist(ByVal catName As String) As Boolean
        Return doesColumnContain("Categories", "name", catName)
    End Function

    Private Function doesColumnContain(ByVal tableName As String, ByVal colName As String, ByVal needle As String) As Boolean
        Dim existingRow() As DataRow = Me.dbData.Tables.Item(tableName).Select(colName & " = '" & needle & "'")
        Return existingRow.Length > 0
    End Function

    Public Sub fillExperimentData(ByRef ex As Experiment)
        Me.fillExperimentDefinitions(ex)
        Dim fields As FieldDefinitions = ex.FieldDefinitions
        Dim data As DataTable = ex.ExperimentData

        Dim recordRows() As DataRow = Me.dbData.Tables.Item("ExperimentRecords").Select("expID = " & ex.ID.ToString())

        If recordRows.Length < 1 Then
            Return
        End If

        fields.nextRow()
        Dim tempRow As DataRow = data.NewRow()
        Dim count As Integer = 0

        For Each row As DataRow In recordRows
            If Not fields.hasNext() Then
                fields.nextRow()
                count = 0
                data.Rows.Add(tempRow)
                tempRow = data.NewRow()
            End If

            Dim rowID As Integer = CInt(row.Item("recordID"))
            Dim tempValue As Object = getRecordValue(rowID)

            Select Case fields.getNext().Type
                Case FieldType.TEXT, FieldType.CHR
                    tempRow.Item(count) = CStr(tempValue)
                Case FieldType.INT, FieldType.UINT, FieldType.BOOL
                    tempRow.Item(count) = CInt(tempValue)
            End Select

            count += 1
        Next

        data.Rows.Add(tempRow)
        ex.ExperimentData = data
    End Sub

    Private Function getRecordValue(ByVal recordID As Integer) As Object
        Dim tempRow() As DataRow

        tempRow = Me.dbData.Tables.Item("Integers").Select("recordID = " & recordID.ToString())

        If tempRow.Length > 0 Then
            Return tempRow(0).Item("storedValue")
        End If

        tempRow = Me.dbData.Tables.Item("Texts").Select("recordID = " & recordID.ToString())

        If tempRow.Length > 0 Then
            Return tempRow(0).Item("storedValue")
        End If

        tempRow = Me.dbData.Tables.Item("Blobs").Select("recordID = " & recordID.ToString())

        If tempRow.Length > 0 Then
            Return tempRow(0).Item("storedValue")
        End If

        ' Missing value in database
        Return Nothing
    End Function

    Public Sub deleteExperiment(ByVal ex As Experiment)
        Dim exRows(), recRows(), valueRows(), fldRows(), catRow, passRow As DataRow
        exRows = Me.dbData.Tables.Item("Experiments").Select("expID = '" & ex.ID & "'")

        If exRows.Length > 0 Then
            ' Delete all field rows for this experiment.
            fldRows = exRows(0).GetChildRows(Me.dbData.Relations.Item("ExExfld"))
            For Each fldRow As DataRow In fldRows
                fldRow.Delete()
            Next
            Me.fieldAdap.Update(Me.dbData, "ExperimentFields")

            ' Loop through record children.
            recRows = exRows(0).GetChildRows(Me.dbData.Relations.Item("ExExrec"))
            For Each recRow As DataRow In recRows
                ' Get the child row for each record row and remove it. We must check each relationship.
                valueRows = recRow.GetChildRows(Me.dbData.Relations.Item("ExrecInts"))
                For Each valRow As DataRow In valueRows
                    valRow.Delete()
                Next
                Me.intAdap.Update(Me.dbData, "Integers")

                valueRows = recRow.GetChildRows(Me.dbData.Relations.Item("ExrecTxts"))
                For Each valRow As DataRow In valueRows
                    valRow.Delete()
                Next
                Me.txtAdap.Update(Me.dbData, "Texts")

                valueRows = recRow.GetChildRows(Me.dbData.Relations.Item("ExrecBlobs"))
                For Each valRow As DataRow In valueRows
                    valRow.Delete()
                Next
                Me.blobAdap.Update(Me.dbData, "Blobs")

                ' Delete the record row itself once it's children are gone.
                recRow.Delete()
            Next
            Me.rcrdAdap.Update(Me.dbData, "ExperimentRecords")

            catRow = exRows(0).GetParentRow(Me.dbData.Relations.Item("CatEx"))
            passRow = exRows(0).GetParentRow(Me.dbData.Relations.Item("PassEx"))

            exRows(0).Delete()
            Me.exAdap.Update(Me.dbData, "Experiments")

            ' Check if the experiment row's parent has no more children. If so, delete it.
            Dim tmpRows() As DataRow = catRow.GetChildRows(Me.dbData.Relations.Item("CatEx"))
            If tmpRows.Length = 0 Then
                catRow.Delete()
            End If
            Me.catAdap.Update(Me.dbData, "Categories")

            ' The row may not have a password set.
            If Not IsNothing(passRow) Then
                tmpRows = passRow.GetChildRows(Me.dbData.Relations.Item("PassEx"))
                If tmpRows.Length = 0 Then
                    passRow.Delete()
                End If
                Me.passAdap.Update(Me.dbData, "Passwords")
            End If

        End If

        Me.dbConnection.Close()
    End Sub

    ' --- Event handlers below ---
    ' We must handle the row updated event for parent tables to succesfully set the foreign key in the child.
    ' This is due to an issue with Access' JET database engine and the OleDbDataAdapter.
    Private Sub onCatRowUpdated(ByVal sender As Object, ByVal e As OleDbRowUpdatedEventArgs) Handles catAdap.RowUpdated
        ' If the event is for a row that has been deleted, we don't need to continue.
        If Not e.Row.RowState = DataRowState.Deleted Then
            ' @@IDENTITY is the latest counter value, and hence the row's primary key value.
            Dim oCmd As New OleDbCommand("SELECT @@IDENTITY", e.Command.Connection)
            ' We need to set the ID in our datarow to match the value it will receive when it is added to the database.
            ' This means we can set the value as a foreign key and be sure that the value will be correct.
            e.Row.Item("catID") = oCmd.ExecuteScalar()
            ' We have changed the value, so we must accept the modifications to the row.
            e.Row.AcceptChanges()
        End If
    End Sub

    Private Sub onPassRowUpdated(ByVal sender As Object, ByVal e As OleDbRowUpdatedEventArgs) Handles passAdap.RowUpdated
        If Not e.Row.RowState = DataRowState.Deleted Then
            Dim oCmd As New OleDbCommand("SELECT @@IDENTITY", e.Command.Connection)
            e.Row.Item("passID") = oCmd.ExecuteScalar()
            e.Row.AcceptChanges()
        End If
    End Sub

    Private Sub onExRowUpdated(ByVal sender As Object, ByVal e As OleDbRowUpdatedEventArgs) Handles exAdap.RowUpdated
        If e.Row.RowState = DataRowState.Added Then
            Dim oCmd As New OleDbCommand("SELECT @@IDENTITY", e.Command.Connection)
            e.Row.Item("expID") = oCmd.ExecuteScalar()
            e.Row.AcceptChanges()
        End If
    End Sub

    Private Sub onRecRowUpdated(ByVal sender As Object, ByVal e As OleDbRowUpdatedEventArgs) Handles rcrdAdap.RowUpdated
        If Not e.Row.RowState = DataRowState.Deleted Then
            Dim oCmd As New OleDbCommand("SELECT @@IDENTITY", e.Command.Connection)
            e.Row.Item("recordID") = oCmd.ExecuteScalar()
            e.Row.AcceptChanges()
        End If
    End Sub

    ' --- Initialisation code below ---
    ' Create DataHandler as a singleton.
    Private Shared instance As DataHandler

    Public Shared Function getInstance() As DataHandler
        If instance Is Nothing Then
            instance = New DataHandler()
        End If

        Return instance
    End Function

    ' Move initialisation code into a separate public sub. This allows us to change database while the program is running.
    Public Function reload() As Boolean
        Try
            ' The connection string used to specify how to connect.
            Me.dbConnStr = "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=" & OptionsDialog.DatabaseLocation & ";"

            ' Create the database if it doesn't exist.
            Me.createDatabase()

            ' Create and open the connection.
            Me.dbConnection = New OleDbConnection(Me.dbConnStr)
            Me.dbConnection.Open()

            ' Create the dataset that will hold experiment data in-memory.
            Me.dbData = New DataSet()

            ' We use a separate data adapter for each table. This makes updating the database much simpler.
            Me.exAdap = New OleDbDataAdapter()
            ' We select all columns from all tables, as we're going to be using all of them in our application.
            Me.exAdap.SelectCommand = New OleDbCommand("SELECT * FROM `Experiments`", Me.dbConnection)
            ' We must use FillSchema first, as this retrieves more detailed information needed for writes.
            Me.exAdap.FillSchema(Me.dbData, SchemaType.Source, "Experiments")
            ' Fill is intended for read-only usage, as it gathers only the minimum amount of schema information needed to load values.
            Me.exAdap.Fill(Me.dbData, "Experiments")
            ' A CommandBuilder is needed to automatically generate the SQL needed to apply the changes made to the DataTable.
            Me.exCmd = New OleDbCommandBuilder(Me.exAdap)

            Me.passAdap = New OleDbDataAdapter()
            Me.passAdap.SelectCommand = New OleDbCommand("SELECT * FROM `Passwords`", Me.dbConnection)
            Me.passAdap.FillSchema(Me.dbData, SchemaType.Source, "Passwords")
            Me.passAdap.Fill(Me.dbData, "Passwords")
            Me.passCmd = New OleDbCommandBuilder(Me.passAdap)

            Me.fieldAdap = New OleDbDataAdapter()
            Me.fieldAdap.SelectCommand = New OleDbCommand("SELECT * FROM `ExperimentFields`", Me.dbConnection)
            Me.fieldAdap.FillSchema(Me.dbData, SchemaType.Source, "ExperimentFields")
            Me.fieldAdap.Fill(Me.dbData, "ExperimentFields")
            Me.fieldCmd = New OleDbCommandBuilder(Me.fieldAdap)

            Me.catAdap = New OleDbDataAdapter()
            Me.catAdap.SelectCommand = New OleDbCommand("SELECT * FROM `Categories`", Me.dbConnection)
            Me.catAdap.FillSchema(Me.dbData, SchemaType.Source, "Categories")
            Me.catAdap.Fill(Me.dbData, "Categories")
            Me.catCmd = New OleDbCommandBuilder(Me.catAdap)

            Me.rcrdAdap = New OleDbDataAdapter()
            Me.rcrdAdap.SelectCommand = New OleDbCommand("SELECT * FROM `ExperimentRecords`", Me.dbConnection)
            Me.rcrdAdap.FillSchema(Me.dbData, SchemaType.Source, "ExperimentRecords")
            Me.rcrdAdap.Fill(Me.dbData, "ExperimentRecords")
            Me.rcrdCmd = New OleDbCommandBuilder(Me.rcrdAdap)

            Me.blobAdap = New OleDbDataAdapter()
            Me.blobAdap.SelectCommand = New OleDbCommand("SELECT * FROM `Blobs`", Me.dbConnection)
            Me.blobAdap.FillSchema(Me.dbData, SchemaType.Source, "Blobs")
            Me.blobAdap.Fill(Me.dbData, "Blobs")
            Me.blobCmd = New OleDbCommandBuilder(Me.blobAdap)

            Me.intAdap = New OleDbDataAdapter()
            Me.intAdap.SelectCommand = New OleDbCommand("SELECT * FROM `Integers`", Me.dbConnection)
            Me.intAdap.FillSchema(Me.dbData, SchemaType.Source, "Integers")
            Me.intAdap.Fill(Me.dbData, "Integers")
            Me.intCmd = New OleDbCommandBuilder(Me.intAdap)
            'Me.intAdap.InsertCommand = New OleDbCommand("INSERT INTO `Integers` (`recordID`, `value`) VALUES (?, ?)", Me.dbConnection)

            Me.txtAdap = New OleDbDataAdapter()
            Me.txtAdap.SelectCommand = New OleDbCommand("SELECT * FROM `Texts`", Me.dbConnection)
            Me.txtAdap.FillSchema(Me.dbData, SchemaType.Source, "Texts")
            Me.txtAdap.Fill(Me.dbData, "Texts")
            Me.txtCmd = New OleDbCommandBuilder(Me.txtAdap)

            ' Parent: Categories / Child: Experiments
            Me.dbData.Relations.Add("CatEx", Me.dbData.Tables("Categories").Columns("catID"), Me.dbData.Tables("Experiments").Columns("catID"))

            ' Parent: Passwords / Child: Experiments
            Me.dbData.Relations.Add("PassEx", Me.dbData.Tables("Passwords").Columns("passID"), Me.dbData.Tables("Experiments").Columns("passID"))

            ' Parent: Experiments / Child: ExperimentFields
            Me.dbData.Relations.Add("ExExfld", Me.dbData.Tables("Experiments").Columns("expID"), Me.dbData.Tables("ExperimentFields").Columns("expID"))

            ' Parent: Experiments / Child: ExperimentRecords
            Me.dbData.Relations.Add("ExExrec", Me.dbData.Tables("Experiments").Columns("expID"), Me.dbData.Tables("ExperimentRecords").Columns("expID"))

            ' Parent: ExperimentRecords / Child: Blobs
            Me.dbData.Relations.Add("ExrecBlobs", Me.dbData.Tables("ExperimentRecords").Columns("recordID"), Me.dbData.Tables("Blobs").Columns("recordID"))

            ' Parent: ExperimentRecords / Child: Integers
            Me.dbData.Relations.Add("ExrecInts", Me.dbData.Tables("ExperimentRecords").Columns("recordID"), Me.dbData.Tables("Integers").Columns("recordID"))

            ' Parent: ExperimentRecords / Child: Texts
            Me.dbData.Relations.Add("ExrecTxts", Me.dbData.Tables("ExperimentRecords").Columns("recordID"), Me.dbData.Tables("Texts").Columns("recordID"))
        Catch
            ' Errors thrown here will stop proper excecution of the rest of the system, so they must be caught and reported.
            ' Errors here, if any, will most likely be an invalid database file. E.g. the user selected an access database not created by us.
            Return False
        End Try

        Return True
    End Function

    ' Default constructor, made private so only this class can instantiate itself. This, together with the shared instance variable
    ' and getInstance method means we have a method of obtaining a reference to the DataHandler object even though we cannot create
    ' a new instance ourselves. This is the singleton design pattern - only one instance of this class can EVER exist at one time,
    ' which is ideal for cases such as database access where we need global access but don't want multiple conflicting copies of data.
    Private Sub New()
        ' Call the reload method.
        If Not Me.reload() Then
            ' Loading the default database has failed, halting program execution.
            ' The user must now intervene.
            MsgBox("Fatal error when loading Serial Data Logger. The default database is invalid, and you must select a valid file before continuing.", MsgBoxStyle.Critical + MsgBoxStyle.OkOnly, "Failed to Load Database")
            Dim opt As New OptionsDialog()
            opt.ShowDialog()
        End If
    End Sub

    Private Sub createDatabase()
        ' Create database file.
        If Not FileIO.FileSystem.FileExists(OptionsDialog.DatabaseLocation) Then
            Debug.Print("Creating a new database file.")
            db.Create(Me.dbConnStr)

            ' Open database connection.
            dbADOConn.ConnectionString = Me.dbConnStr
            dbADOConn.Open()

            ' Create tables.
            Dim dbCmd As New ADODB.Command
            Dim strSQL As String

            strSQL = "CREATE TABLE `Experiments` " & _
            "(`expID` COUNTER CONSTRAINT PrimaryKey PRIMARY KEY, " & _
            "`name` TEXT (128), " & _
            "`owner` TEXT (64), " & _
            "`catID` LONG, " & _
            "`passID` LONG, " & _
            "`notes` TEXT (255), " & _
            "`dateCreated` DATETIME DEFAULT NOW())"

            dbCmd.CommandText = strSQL
            dbCmd.ActiveConnection = dbADOConn
            dbCmd.Execute()
            Debug.Print("Experiments table created.")

            strSQL = "CREATE TABLE `Passwords` " & _
            "(`passID` COUNTER CONSTRAINT PrimaryKey PRIMARY KEY, " & _
            "`passHash` TEXT (128), " & _
            "`passSalt` TEXT (12))"

            dbCmd.CommandText = strSQL
            dbCmd.ActiveConnection = dbADOConn
            dbCmd.Execute()
            Debug.Print("Passwords table created.")

            strSQL = "CREATE TABLE `Categories` " & _
            "(`catID` COUNTER CONSTRAINT PrimaryKey PRIMARY KEY, " & _
            "`name` TEXT (128))"

            dbCmd.CommandText = strSQL
            dbCmd.ActiveConnection = dbADOConn
            dbCmd.Execute()
            Debug.Print("Categories table created.")

            strSQL = "CREATE TABLE `ExperimentRecords` " & _
            "(`expID` LONG, " & _
            "`recordID` COUNTER CONSTRAINT PrimaryKey PRIMARY KEY)"

            dbCmd.CommandText = strSQL
            dbCmd.ActiveConnection = dbADOConn
            dbCmd.Execute()
            Debug.Print("ExperimentRecords table created.")

            ' We add a special constraint to enforce that fieldCount is unique for each expID.
            strSQL = "CREATE TABLE `ExperimentFields` " & _
            "(`expID` LONG, " & _
            "`fieldCount` INTEGER, " & _
            "`fieldHeader` TEXT (30), " & _
            "`dataType` TINYINT, " & _
            "CONSTRAINT `UniqueField` UNIQUE(`expID`, `fieldCount`))"

            dbCmd.CommandText = strSQL
            dbCmd.ActiveConnection = dbADOConn
            dbCmd.Execute()
            Debug.Print("ExperimentFields table created.")

            strSQL = "CREATE TABLE `Integers` " & _
            "(`recordID` LONG CONSTRAINT PrimaryKey PRIMARY KEY, " & _
            "`storedValue` INTEGER)"

            dbCmd.CommandText = strSQL
            dbCmd.ActiveConnection = dbADOConn
            dbCmd.Execute()
            Debug.Print("Integers table created.")

            strSQL = "CREATE TABLE `Texts` " & _
            "(`recordID` LONG CONSTRAINT PrimaryKey PRIMARY KEY, " & _
            "`storedValue` TEXT (255))"

            dbCmd.CommandText = strSQL
            dbCmd.ActiveConnection = dbADOConn
            dbCmd.Execute()
            Debug.Print("Texts table created.")

            dbADOConn.Close()
        Else
            Debug.Print("Database file found, not modifying.")
        End If
    End Sub
End Class

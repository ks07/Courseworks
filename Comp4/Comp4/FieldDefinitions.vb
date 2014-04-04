Imports System.Collections.ObjectModel

Public Class FieldDefinitions
    Private fieldList As New List(Of Field)
    Private count As Integer = -1
    Private order As Integer = 1

    Public Sub registerFields(ByRef fields() As Field)
        fieldList.Clear()
        Me.order = 1

        For Each field As Field In fields
            Me.registerAdditionalField(field)
        Next
    End Sub

    Public Sub registerAdditionalField(ByRef field As Field)
        field.Count = Me.order
        fieldList.Add(field)
        Me.order += 1
    End Sub

    Public Function getFieldList() As ReadOnlyCollection(Of Field)
        Return fieldList.AsReadOnly()
    End Function

    Public Function getNext() As Field
        count += 1
        Return fieldList(count)
    End Function

    Public Function hasNext() As Boolean
        Return count < (fieldList.Count - 1)
    End Function

    Public Sub nextRow()
        count = -1
    End Sub

    Public Function getCount() As Integer
        Return fieldList.Count()
    End Function

End Class

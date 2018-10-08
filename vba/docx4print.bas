Attribute VB_Name = "NewMacros"
Option Explicit

Sub Docx4Print()
' @VERSION 1.0.2
' @AUTHOR  WisdomFusion
'
' �Ҷ�����Щʲô�ģ�
' - �����ӵ�ͼƬ���ػ�����һ��������������Ϊ�ǰ����ϵ�ͼƬץץץ�����ش�������
' - �淶��ʽ
' - ����ҳ��
'

    Dim oDoc As Document
    Dim objFileDialog As FileDialog
    
    ' ���ļ��Ի���
    Set objFileDialog = Application.FileDialog(msoFileDialogFilePicker)
    objFileDialog.AllowMultiSelect = False
    objFileDialog.Filters.Clear
    objFileDialog.Filters.Add "Word files", "*.docx, *.doc"
    
    If objFileDialog.Show = -1 Then
        Set oDoc = Documents.Open(FileName:=objFileDialog.SelectedItems(1), AddToRecentFiles:=False)
    End If
    
    ' û�򿪣�
    If oDoc Is Nothing Then
        MsgBox "Woops! no doc is opened..."
        Exit Sub
    End If
    
    ' ���� docx
    Dim strFilePath As String
    strFilePath = oDoc.Path & Application.PathSeparator & oDoc.Name
    strFilePath = Mid(strFilePath, 1, InStrRev(strFilePath, ".") - 1)
    strFilePath = strFilePath & "_print"
    oDoc.SaveAs2 FileName:=strFilePath, fileformat:=wdFormatDocumentDefault

    ' �����ӵ�ͼƬ���ػ�
    ConvertLinked oDoc
    
    ' ��׼����ʽ
    StandardizeStyles oDoc
    
    ' ���ҳ��
    AddFooter oDoc
    
    ' ɾ��ҳü
    DeleteAllHeaders oDoc
    
    oDoc.Save
    
    oDoc.Close
    
    MsgBox "aha, DONE!"

End Sub


Private Sub ConvertLinked(oDoc As Document)
' �����ӵ�ͼƬ���ػ�
    
    Debug.Print "ConvertLinked"

    Dim objShape As Shape
    Dim objInlineShape As InlineShape
    
    For Each objShape In oDoc.Shapes
        If objShape.Type = msoLinkedPicture Then
            objShape.LinkFormat.SavePictureWithDocument = True
            objShape.LinkFormat.BreakLink
        End If
    Next objShape
    
    For Each objInlineShape In oDoc.InlineShapes
        If objInlineShape.Type = wdInlineShapeLinkedPicture Then
            objInlineShape.LinkFormat.SavePictureWithDocument = True
            objInlineShape.LinkFormat.BreakLink
        End If
    Next objInlineShape

End Sub

Private Sub AddFooter(oDoc As Document)
' ���ҳ��

    Debug.Print "AddFooter"
    
    Dim oRange As Range
    Dim oRangePage As Range
    Dim oRangeNumPages As Range

    With oDoc.Sections(1)
    
        With .Footers(wdHeaderFooterPrimary)
            .Range.Text = "�� PAGE ҳ / �� NUMPAGES ҳ"
            .Range.ParagraphFormat.Alignment = wdAlignParagraphCenter
            
            ConvertFields .Range, "NUMPAGES"
            ConvertFields .Range, "PAGE"
            
            .Range.Fields.Update
        End With
    End With

End Sub

Private Sub DeleteAllHeaders(oDoc As Document)
' ɾ�����е�ҳü����ΪĿǰû��������󣬱�����ִ����ߵĿ�ҳü

    Dim objSection As Section
    Dim objHeader As HeaderFooter
    
    For Each objSection In oDoc.Sections
        For Each objHeader In objSection.Headers
            objHeader.Range.Delete
        Next objHeader
    Next objSection

End Sub

Private Sub StandardizeStyles(oDoc As Document)
' ��׼����ʽ

    Debug.Print "StandardizeStyles"
    
    ' ��û��á�������˵�ɡ�����
    ' �㣡����������
    
End Sub

Private Sub ConvertFields(oRange As Range, Optional strText As String)
    With oRange.Find
        .Text = strText
        .MatchCase = True
        .MatchWholeWord = True
        
        While .Execute
            oRange.Fields.Add oRange, wdFieldEmpty, , False
            oRange.Collapse wdCollapseEnd
        Wend
    End With
End Sub


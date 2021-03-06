Attribute VB_Name = "NewMacros"
Option Explicit

Sub Docx4Print()
' @VERSION 1.0.2
' @AUTHOR  WisdomFusion
'
' 我都干了些什么的：
' - 把链接的图片本地化（这一步必须联网，因为是把网上的图片抓抓抓到本地存起来）
' - 规范样式
' - 加上页码
'

    Dim oDoc As Document
    Dim objFileDialog As FileDialog
    
    ' 打开文件对话框
    Set objFileDialog = Application.FileDialog(msoFileDialogFilePicker)
    objFileDialog.AllowMultiSelect = False
    objFileDialog.Filters.Clear
    objFileDialog.Filters.Add "Word files", "*.docx, *.doc"
    
    If objFileDialog.Show = -1 Then
        Set oDoc = Documents.Open(FileName:=objFileDialog.SelectedItems(1), AddToRecentFiles:=False)
    End If
    
    ' 没打开？
    If oDoc Is Nothing Then
        MsgBox "Woops! no doc is opened..."
        Exit Sub
    End If
    
    ' 另存成 docx
    Dim strFilePath As String
    strFilePath = oDoc.Path & Application.PathSeparator & oDoc.Name
    strFilePath = Mid(strFilePath, 1, InStrRev(strFilePath, ".") - 1)
    strFilePath = strFilePath & "_print"
    oDoc.SaveAs2 FileName:=strFilePath, fileformat:=wdFormatDocumentDefault

    ' 把链接的图片本地化
    ConvertLinked oDoc
    
    ' 标准化样式
    StandardizeStyles oDoc
    
    ' 添加页脚
    AddFooter oDoc
    
    ' 删除页眉
    DeleteAllHeaders oDoc
    
    oDoc.Save
    
    oDoc.Close
    
    MsgBox "aha, DONE!"

End Sub


Private Sub ConvertLinked(oDoc As Document)
' 把链接的图片本地化
    
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
' 添加页脚

    Debug.Print "AddFooter"
    
    Dim oRange As Range
    Dim oRangePage As Range
    Dim oRangeNumPages As Range

    With oDoc.Sections(1)
    
        With .Footers(wdHeaderFooterPrimary)
            .Range.Text = "第 PAGE 页 / 共 NUMPAGES 页"
            .Range.ParagraphFormat.Alignment = wdAlignParagraphCenter
            
            ConvertFields .Range, "NUMPAGES"
            ConvertFields .Range, "PAGE"
            
            .Range.Fields.Update
        End With
    End With

End Sub

Private Sub DeleteAllHeaders(oDoc As Document)
' 删除所有的页眉，因为目前没有这个需求，避免出现带横线的空页眉

    Dim objSection As Section
    Dim objHeader As HeaderFooter
    
    For Each objSection In oDoc.Sections
        For Each objHeader In objSection.Headers
            objHeader.Range.Delete
        Next objHeader
    Next objSection

End Sub

Private Sub StandardizeStyles(oDoc As Document)
' 标准化样式

    Debug.Print "StandardizeStyles"
    
    ' 还没想好。。。再说吧。。。
    ' 你！可以提需求！
    
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


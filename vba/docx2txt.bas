Attribute VB_Name = "ģ��1"
Option Explicit
Option Base 1

Sub Docx2Txt()
' �ҵ��԰ף�
' 1. �������ú�� Word �ĵ������ڳ��δ���ʱ���ú�
' 2. �Ҵ򿪵��� docx���³����� jpg �� txt��txt ���� UTF-8-BOM Unix(LF)
' 3. ���Ҵ����ĵ�ǰ�������ذ�װ ImageMagick�����ڵ���ͼƬ�ļ���ת����http://imagemagick.org/script/download.php#windows
' 4. Ϊ�����ļ����ң�����ҷ���һ���ɸɾ������ļ�����
' 5. �Ҳ���������Ҫ������ bugfix
    
    Dim strMainPath As String
    Dim strNewPath As String
    Dim fileDialog As fileDialog
    Dim docToProcess As Document
    
    ' ���ļ������ļ��У�Ҳ�������ļ�֮����
    strMainPath = ActiveDocument.Path
    
    ' ѡ��Ҫ����� docx �ļ�
    Set fileDialog = Application.fileDialog(msoFileDialogFilePicker)
    fileDialog.AllowMultiSelect = False
    fileDialog.Filters.Clear
    fileDialog.Filters.Add "Word files", "*.docx"
    
    If fileDialog.Show = -1 Then
        'Debug.Print fileDialog.SelectedItems(1)
        Set docToProcess = Documents.Open(FileName:=fileDialog.SelectedItems(1), AddToRecentFiles:=False, Visible:=False)
    End If
    
    On Error GoTo ErrorHandle

    ' ���һ�����ļ���ԭ�ļ��Ҳ���
    strNewPath = strMainPath & Application.PathSeparator & docToProcess.Name
    docToProcess.SaveAs2 FileName:=strNewPath
    
    ' =========================== START ==========================
    ' ���´���˳�����Ҫ�ģ�
    
    Application.ScreenUpdating = False
    
    ConvertSuperscriptToHtml docToProcess ' �ϱ�
    ConvertSubscriptToHtml docToProcess   ' �±�
    
    ' ѡ������Ŀ���תΪ�ı�
    ConvertListsInOptionsToText docToProcess
    ' ��ŵ���Ŀ���ת�ı�
    ConvertQuestionNoListParagraphsToText docToProcess
    
    ' ��ɺʹ��е��б�תΪ ol,ul �� HTML ��ǩ
    ' Ŀǰֻ֧��һ���б�Ƕ���б��������
    ConvertListsInBodyToHtml docToProcess
    
    ' ������ʽȫ����Ϊ������ʽ
    PreprocessDocumentFormat docToProcess
    
    ' ���תΪ HTML ��ǩ
    ' Ŀǰֻ֧����ͨ�����к���Ԫ��ϲ��ı��
    ' ��������������Ԫ��ϲ��ı��
    ConvertTablesToHtml docToProcess
    
    ' �����ĵ������е�ͼƬ
    SaveImagesToDiskFiles docToProcess
    ' emf ת jpg��ͬʱɾ�� emf �ļ�
    ConvertEmfToJpg docToProcess
    
    ProcessQuestionBody docToProcess   ' �������
    ProcessQuestionOption docToProcess ' ����ѡ��
    ProcessAnswer docToProcess         ' �����
    PrepareQuestionAttr docToProcess   ' ������Ŀ�����ֶΣ��ѷ��ࡢ��š����͵���Ŀ�ֶ�ת�ɴ�����ĸ�ʽ
    
    ' ���ѹأ�����������ʽ
    PostprocessDocumentFormat docToProcess

    docToProcess.Save

    Application.ScreenUpdating = True

    ' ���Ϊ txt
    SaveMeToTxt docToProcess
    
    MsgBox "Hah, DONE!"
    
ErrorHandle:
    Debug.Print Err.Description
End Sub

Private Sub PreprocessDocumentFormat(docToProcess As Document)
' Ԥ�����ʽ

    With docToProcess.Content.Find
        .ClearFormatting
        .Execute FindText:="^l", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="^13{2,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="^13[  ^9]{1,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="[  ^9]{1,}^13", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
    End With
End Sub

Private Sub PostprocessDocumentFormat(docToProcess As Document)
' �����һ��������ʽ

    docToProcess.Range.Select
    
    If StyleExists("����", docToProcess) = True Then
        Selection.Style = "����"
    ElseIf StyleExists("Normal", docToProcess) = True Then
        Selection.Style = "Normal"
    End If
    
    With docToProcess.Content.Find
        .ClearFormatting
        .Execute FindText:="</p>^p<", ReplaceWith:="</p><", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<p><table", ReplaceWith:="<table", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</table></p>", ReplaceWith:="</table>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
End Sub

Private Sub PrepareQuestionAttr(docToProcess As Document)
' ������Ŀ�ֶ�
    
    With docToProcess.Content.Find
        .ClearFormatting
        .Execute FindText:="(����š�*)(����š�)", ReplaceWith:="\1=end^p\2", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="�����ࡿ", ReplaceWith:="=category#", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="����š�", ReplaceWith:="=no#", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����͡���ѡ", ReplaceWith:="=type#single_choice", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����͡���ѡ", ReplaceWith:="=type#multiple_choice", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����͡��ʴ�", ReplaceWith:="=type#subjective_question", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="���Ѷȡ�����", ReplaceWith:="=level#3", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="���Ѷȡ����", ReplaceWith:="=level#2", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="���Ѷȡ���", ReplaceWith:="=level#1", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����⡿��", ReplaceWith:="=special#T", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����⡿", ReplaceWith:="=special#", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�������ʽ������", ReplaceWith:="=format#grid", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�������ʽ�����", ReplaceWith:="=format#table", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
    End With
End Sub

Private Sub ConvertTablesToHtml(docToProcess As Document)
' �ѱ��תΪ HTML ����ǰ��Ԥ����

    Dim oTable As Table
    Dim i As Integer
    
    ' ���ǰ��ӿ���
    For i = docToProcess.Tables.Count To 1 Step -1
        docToProcess.Tables(i).Range.Select
        With Selection
            .Cut
            .Text = vbCrLf & vbCrLf & vbCrLf
            .End = .End - 1
            .start = .start + 1
            .Paste
        End With
    Next
    
    IterateTables docToProcess
    
End Sub

Private Sub IterateTables(docToProcess As Document)
' �ѱ��תΪ HTML

    Dim i As Integer ' �������
    Dim j As Integer ' ����еĵ�Ԫ������
    Dim k As Integer ' ��������ж�ά����
    Dim l As Integer ' ��������ж�ά����
    
    Dim objTable As Table
    Dim objCell As Cell
    
    Dim intRowSpan As Integer
    Dim intColSpan As Integer
    
    Dim strTable As String  ' ĳ��������յ� HTML ����
    Dim arrRows() As String ' ĳ������������
    
    ' ������ǰ�ĵ������еı��
    For i = docToProcess.Tables.Count To 1 Step -1
        Set objTable = docToProcess.Tables(i)
        strTable = "<table>"
        
        ' �ض����ű�������ݵĶ�ά����
        ReDim arrRows(objTable.Rows.Count, objTable.Columns.Count)
        
        ' ��������еĵ�Ԫ��
        For j = 1 To objTable.Range.Cells.Count
            Set objCell = objTable.Range.Cells(j)
            objCell.Select
            intRowSpan = Selection.Information(wdEndOfRangeRowNumber) - Selection.Information(wdStartOfRangeRowNumber) + 1
            'Debug.Print "rowspan=" & intRowSpan
            intColSpan = Selection.Information(wdEndOfRangeColumnNumber) - Selection.Information(wdStartOfRangeColumnNumber) + 1
            'Debug.Print "colspan=" & intColSpan
            
            Dim strTd As String
            strTd = "<td"
            
            If intRowSpan > 1 Then
                strTd = strTd & " rowspan=""" & intRowSpan & """"
            End If
            
            If intColSpan > 1 Then
                strTd = strTd & " colspan=""" & intColSpan & """"
            End If
            
            strTd = strTd & ">"
            
            Dim strTdText As String
            strTdText = Replace(Replace(Selection.Text, Chr(7), ""), Chr(13), "<br />")
            strTdText = strTd & strTdText & "</td>"
            ' �� Chr(7) �滻Ϊ "" �󣬺����� Chr(13) ��������
            strTdText = Replace(strTdText, "<br /></td>", "</td>")
            
            arrRows(objCell.RowIndex, objCell.ColumnIndex) = strTdText
        Next j ' objTable.Range.Cells
        
        ' ƴ�ӽ��
        Dim strTr As String
        For k = LBound(arrRows, 1) To UBound(arrRows, 1)
            strTr = "<tr>"
            
            For l = LBound(arrRows, 2) To UBound(arrRows, 2)
                strTr = strTr & arrRows(k, l)
            Next l
            
            strTr = strTr & "</tr>"
            strTable = strTable & strTr
        Next k
        
        strTable = strTable & "</table>"
        
        'Debug.Print strTable & vbCrLf
        
        ' �滻���ĵ���
        objTable.Select
        Selection.Cut
        Selection.InsertBefore strTable
        
    Next i ' ActiveDocument.Tables

End Sub

Private Sub ConvertListsInOptionsToText(docToProcess As Document)
' ѡ���е���Ŀ���ת������
' �Ȱ�ѡ���е���Ŀ��Ŵ���������� ConvertListsInQuestionBodyToHtml ��������е���Ŀ���

    Dim oPara As Paragraph
    
    With docToProcess.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="��ѡ�*���𰸡�", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            For Each oPara In Selection.Range.listParagraphs
                oPara.Range.ListFormat.ConvertNumbersToText
            Next oPara
            
            .Execute
        Loop
    End With
End Sub

Private Sub ConvertQuestionNoListParagraphsToText(docToProcess As Document)
' ��ŵ���Ŀ���ת�ı�

    Dim oPara As Paragraph
    
    For Each oPara In docToProcess.listParagraphs
        If StartsWith(oPara.Range.ListFormat.ListString, "����š�") = True Then
            oPara.Range.ListFormat.ConvertNumbersToText
        End If
    Next oPara
End Sub

Private Sub ConvertListsInBodyToHtml(docToProcess As Document)
' ��ɡ��𰸻��������Ŀ���ת�� HTML

    Dim oList As List
    Dim oPara As Paragraph
    
    For Each oList In docToProcess.Lists
        With oList.Range
            .MoveStart Unit:=wdCharacter, Count:=-1
            .Select
        End With
        
        ' �� List ����β���� <ol></ol> <ul type="A|1"></ul> HTML��ǩ
        With oList.listParagraphs(1).Range.ListFormat
            If .ListType = WdListType.wdListSimpleNumbering Then
                Selection.InsertBefore (vbCrLf & "<ol type=""" & Left(.ListString, 1) & """>")
                Selection.InsertAfter ("</ol>" & vbCrLf)
            End If
            
            If .ListType = WdListType.wdListBullet Then
                Selection.InsertBefore (vbCrLf & "<ul>")
                Selection.InsertAfter ("</ul>" & vbCrLf)
            End If
        End With
        
        Dim strStyleName As String
        
        If StyleExists("����", docToProcess) = True Then
            strStyleName = "����"
        ElseIf StyleExists("Normal", docToProcess) = True Then
            strStyleName = "Normal"
        End If
        
        ' �б������˼� <li></li> ��ǩ
        For Each oPara In oList.listParagraphs
            With oPara.Range
                .Style = strStyleName
                .Text = "<li>" & .Text & "</li>"
            End With
        Next
    Next
    
    ' ����������е� </li> ��ǩ
    With docToProcess.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="^p</li>", ReplaceWith:="</li>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<ul>^p", ReplaceWith:="<ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="(\<ol[!>]@\>)^13", ReplaceWith:="\1", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=True
        .Execute FindText:="</ul>^p<ul>", ReplaceWith:="</ul><ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ul>^p<ol", ReplaceWith:="</ul><ol", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ol>^p<ul>", ReplaceWith:="</ol><ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ol>^p<ol", ReplaceWith:="</ul><ol", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
End Sub

Private Sub ProcessQuestionBody(docToProcess As Document)
' �������
    
    Dim oRange As Range
    Dim oPara As Paragraph
    Dim strBody As String
    Dim strPara As String
    
    ' ����ɡ� ��������
    With docToProcess.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="����ɡ�", ReplaceWith:="����ɡ�^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
    
    ' ��������ɡ��͡� ֮��Ĳ���
    Set oRange = docToProcess.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="����ɡ�*��", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            oRange.MoveStart Unit:=wdCharacter, Count:=5
            oRange.MoveEnd Unit:=wdCharacter, Count:=-1
            'Debug.Print oRange.Text
            oRange.Select
            
            strBody = ""
            For Each oPara In Selection.Range.Paragraphs
                strPara = oPara.Range.Text
                strPara = Replace(strPara, vbCrLf, "")
                strPara = Replace(strPara, vbCr, "")
                strBody = strBody & "<p>" & strPara & "</p>"
            Next oPara
            'Debug.Print strBody
            
            Selection.Cut
            Selection.InsertBefore strBody & vbCrLf
            
            .Execute
        Loop
    End With
    
    ' �޳������ <p></p> ��ǩ
    With docToProcess.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="<p><ol", ReplaceWith:="<ol", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ol></p>", ReplaceWith:="</ol>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<p><ul>", ReplaceWith:="<ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ul></p>", ReplaceWith:="</ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="����ɡ�^p", ReplaceWith:="=body#", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
End Sub

Private Sub ProcessAnswer(docToProcess As Document)
' ��������۵Ĵ�
    
    Dim oRange As Range
    Dim oPara As Paragraph
    Dim strBody As String
    Dim strPara As String
    
    ' ���𰸡� ��������
    With docToProcess.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="���𰸡�", ReplaceWith:="���𰸡�^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="^13{2,}", ReplaceWith:="^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
    
    ' �������𰸡��͡� ֮��Ĳ���
    Set oRange = docToProcess.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="���𰸡�*��", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            oRange.MoveStart Unit:=wdCharacter, Count:=5
            oRange.MoveEnd Unit:=wdCharacter, Count:=-1
            'Debug.Print oRange.Text
            oRange.Select
            
            strBody = ""
            For Each oPara In Selection.Range.Paragraphs
                strPara = oPara.Range.Text
                strPara = Replace(strPara, vbCrLf, "")
                strPara = Replace(strPara, vbCr, "")
                strBody = strBody & "<p>" & strPara & "</p>"
            Next oPara
            'Debug.Print strBody
            
            Selection.Cut
            Selection.InsertBefore strBody & vbCrLf
            
            .Execute
        Loop
    End With
    
    ' �޳������ <p></p> ��ǩ
    With docToProcess.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="<p><ol", ReplaceWith:="<ol", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ol></p>", ReplaceWith:="</ol>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<p><ul>", ReplaceWith:="<ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ul></p>", ReplaceWith:="</ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="���𰸡�^p", ReplaceWith:="=answer#", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
End Sub

Private Sub ProcessQuestionOption(docToProcess As Document)
' ����ѡ��
    
    Dim oRange As Range
    Dim i As Integer
    Dim strOptions As String
    Dim strOptionAnswer As String
    
    ' ����ѡ��
    With docToProcess.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="^13([A-Z])[.�� ]^9", ReplaceWith:="^p\1#", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
    
    ' ����ѡ������
    Set oRange = docToProcess.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="��ѡ�*���𰸡�[A-Z]{1,}^13", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            strOptions = oRange.Text
            'Debug.Print strOptions
            
            strOptionAnswer = Mid(oRange.Text, InStr(1, oRange.Text, "���𰸡�") + 4)
            strOptionAnswer = Replace(strOptionAnswer, vbCrLf, "")
            strOptionAnswer = Replace(strOptionAnswer, vbCr, "")
            'Debug.Print strOptionAnswer
            
            ' �����ȷѡ��ı��
            For i = 1 To Len(strOptionAnswer)
                strOptions = Replace(strOptions, Mid(strOptionAnswer, i, 1) & "#", Mid(strOptionAnswer, i, 1) & "#T#")
            Next
            
            'Debug.Print strOptions
            
            ' �滻���ĵ���
            oRange.Cut
            oRange.InsertBefore strOptions
            
            .Execute
        Loop
    End With
    
    ' ��ѡ���滻�� =option# ��ͷ�ĸ�ʽ
    ' �޳���ѡ���
    ' �޳�ѡ����ġ��𰸡���
    With docToProcess.Range.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="^13[A-Z]#", ReplaceWith:="^p=option#", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
        .Execute FindText:="��ѡ�^p", ReplaceWith:="", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="^13���𰸡�[A-D]{1,}^13", ReplaceWith:="^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
End Sub

Private Sub ConvertSuperscriptToHtml(docToProcess As Document)
' ���ϱ�תΪ <sup></sup>

    docToProcess.Select
   
    With Selection.Find
   
        .ClearFormatting
        .Font.Superscript = True
        .Text = ""
       
        .Format = True
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
       
        .Forward = True
        .Wrap = wdFindContinue
       
        Do While .Execute
            With Selection
                If InStr(1, .Text, vbCr) Then
                    ' Just process the chunk before any newline characters
                    ' We'll pick-up the rest with the next search
                    .Font.Superscript = False
                    .Collapse
                    .MoveEndUntil vbCr
                End If
                                       
                ' Don't bother to markup newline characters (prevents a loop, as well)
                If Not .Text = vbCr Then
                    .InsertBefore "<sup>"
                    .InsertAfter "</sup>"
                End If
               
                .Font.Superscript = False
            End With
        Loop
    End With
End Sub

Private Sub ConvertSubscriptToHtml(docToProcess As Document)
' ���±�תΪ <sub></sub>

    docToProcess.Select
   
    With Selection.Find
   
        .ClearFormatting
        .Font.Subscript = True
        .Text = ""
       
        .Format = True
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
       
        .Forward = True
        .Wrap = wdFindContinue
       
        Do While .Execute
            With Selection
                If InStr(1, .Text, vbCr) Then
                    ' Just process the chunk before any newline characters
                    ' We'll pick-up the rest with the next search
                    .Font.Subscript = False
                    .Collapse
                    .MoveEndUntil vbCr
                End If
                                       
                ' Don't bother to markup newline characters (prevents a loop, as well)
                If Not .Text = vbCr Then
                    .InsertBefore "<sub>"
                    .InsertAfter "</sub>"
                End If
               
                .Font.Subscript = False
            End With
        Loop
    End With
End Sub

Private Sub SaveImagesToDiskFiles(docToProcess As Document)
' ��ͼƬ���Ϊ�ļ�
' �����ı�ͼƬ�滻Ϊ���� [img]201809121523_001.jpg[/img] �� BBCode ��ʽ

    Dim objShape As InlineShape
    Dim byteData() As Byte
    Dim i As Long
    Dim intWritePos As Long
    Dim strOutFilePath As String
    Dim strPictureFileName As String
    Dim strDateTime As String
    
    strDateTime = Format(Now(), "YYYYMMDDHHmm_") ' ��ǰʱ�� ������ʱ��
    
    For i = docToProcess.InlineShapes.Count To 1 Step -1
        Set objShape = docToProcess.InlineShapes(i)
        objShape.Select
        
        strPictureFileName = strDateTime & PadNumber(CStr(i), 2)
        ' �ȴ�� emf������ check �����ļ�ʱ��תΪ jpg
        strOutFilePath = docToProcess.Path & Application.PathSeparator & strPictureFileName & ".emf"
        
        ' �����ļ�
        Open strOutFilePath For Binary Access Write As #1
        byteData = objShape.Range.EnhMetaFileBits
        intWritePos = 1
        Put #1, intWritePos, byteData
        Close #1
        
        ' �滻�ļ���ͼƬ
        Selection.Cut
        Selection.InsertBefore "[img]" & strPictureFileName & ".jpg[/img]"
    Next i
End Sub

Private Sub ConvertEmfToJpg(docToProcess As Document)
' �����ɵ� emf ת�� jpg

    Dim imgFileName As String
    Dim newFileName As String
    Dim strCmd As String
    
    ChDrive Left(docToProcess.Path, 1)
    ChDir docToProcess.Path
    
    imgFileName = Dir("*.emf")
    Do While imgFileName <> ""
        newFileName = Replace(imgFileName, ".emf", ".jpg")
        ' cmd /S /C magick 201809171713_01.emf 201809171713_01.jpg && del 201809171713_01.emf
        strCmd = "cmd /S /C magick " & imgFileName & " " & newFileName & " && del " & imgFileName
        'Debug.Print strCmd
        Call Shell(strCmd, vbHide)
        
        imgFileName = Dir()
    Loop
    
End Sub

Private Sub SaveMeToTxt(docToProcess As Document)
' ������ı��ļ�
    
    Dim strFilePath As String
    strFilePath = docToProcess.Path & Application.PathSeparator & docToProcess.Name
    strFilePath = Mid(strFilePath, 1, InStrRev(strFilePath, ".") - 1)
    
    docToProcess.SaveAs2 FileName:=strFilePath, FileFormat:= _
        wdFormatText, LockComments:=False, Password:="", AddToRecentFiles:=False, _
        WritePassword:="", ReadOnlyRecommended:=False, EmbedTrueTypeFonts:=False, _
         SaveNativePictureFormat:=False, SaveFormsData:=False, SaveAsAOCELetter:= _
        False, Encoding:=65001, InsertLineBreaks:=False, AllowSubstitutions:= _
        False, LineEnding:=wdLFOnly, CompatibilityMode:=0
    docToProcess.Close
End Sub

Private Function PadNumber(intNumber As Integer, intLength As Integer) As String
' ����ǰ׺ 0

    Dim strZeros As String
    Dim i As Integer
    For i = 1 To intLength
        strZeros = strZeros & "0"
    Next
    
    PadNumber = Right(strZeros & CStr(intNumber), intLength)
End Function

Private Function EndsWith(str As String, ending As String) As Boolean
' �ַ����Ƿ���ĳ�ַ���Ϊ��β

     Dim endingLen As Integer
     endingLen = Len(ending)
     EndsWith = (Right(Trim(UCase(str)), endingLen) = UCase(ending))
End Function

Private Function StartsWith(str As String, start As String) As Boolean
' �ַ����Ƿ���ĳ�ַ���Ϊ��ͷ

     Dim startLen As Integer
     startLen = Len(start)
     StartsWith = (Left(Trim(UCase(str)), startLen) = UCase(start))
End Function

Private Function StyleExists(strStyleName As String, doc As Document) As Boolean
' ָ�� Document ���Ƿ���ָ����ʽ
    
    Dim objStyle As Style
    Dim blnStyleExists As Boolean
    
    StyleExists = False
    
    For Each objStyle In doc.Styles
        If objStyle.NameLocal = strStyleName Then
            StyleExists = True
            
            Exit For
        End If
    Next objStyle
End Function

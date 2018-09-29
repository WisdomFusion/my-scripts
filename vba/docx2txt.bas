Attribute VB_Name = "ģ��1"
Option Explicit
Option Base 1

Sub Docx2Txt()
' @VERSION 1.2.0
' @AUTHOR  WisdomFusion
'
' �ҵ��԰ף�
' 1. �������ú�� Word �ĵ������ڳ��δ���ʱ���ú�
' 2. �Ҵ򿪵��� docx���³����� jpg �� txt��txt ���� UTF-8-BOM Unix(LF)
' 3. ���Ҵ����ĵ�ǰ���ȴ� VBE���˵��� ���� -> ����...����ѡ��Microsoft Excel 16.0 Object Library��
'    ��Ϊ���� Word �ĵ�����ͼƬʱ�� Excel ֮��
' 4. Ϊ�����ļ����ң�����ҷ���һ���ɸɾ������ļ�����
' 5. �Ҳ���������Ҫ������ bugfix
'
' CHANGELOG:
' - 20180920 ���ƿմ𰸺Ϳ�ѡ������
' - 20180926 ����ѡ����������[img] ���Ƴ� [img=w,h] ��ʽ
'
    
    Dim strMainPath As String
    Dim strNewPath As String
    Dim objFileDialog As fileDialog
    Dim oDoc As Document
    
    ' ���ļ������ļ��У�Ҳ�������ļ�֮����
    strMainPath = ActiveDocument.Path
    
    ' ѡ��Ҫ����� docx �ļ�
    Set objFileDialog = Application.fileDialog(msoFileDialogFilePicker)
    objFileDialog.AllowMultiSelect = False
    objFileDialog.Filters.Clear
    objFileDialog.Filters.Add "Word files", "*.docx"
    
    If objFileDialog.Show = -1 Then
        Set oDoc = Documents.Open(FileName:=objFileDialog.SelectedItems(1), AddToRecentFiles:=False)
    End If
    
    ' ���û��ѡ�ļ�������Ȼ���˳����ټ�
    If oDoc Is Nothing Then
        MsgBox "Woops! no doc is opened..."
        Exit Sub
    End If

    ' ���һ�����ļ���ԭ�ļ��Ҳ���
    strNewPath = strMainPath & Application.PathSeparator & oDoc.Name
    oDoc.SaveAs2 FileName:=strNewPath
    
    ' =========================== START ==========================
    ' ���´���˳�����Ҫ�ģ�
    
    Application.ScreenUpdating = False
    
    ConvertSuperscriptToHtml oDoc ' �ϱ�
    ConvertSubscriptToHtml oDoc   ' �±�
    
    ' ѡ������Ŀ���תΪ�ı�
    ConvertListsInOptionsToText oDoc
    ' ��ŵ���Ŀ���ת�ı�
    ConvertQuestionNoListsToText oDoc
    
    ' ��ɺʹ��е��б�תΪ ol,ul �� HTML ��ǩ
    ' Ŀǰֻ֧��һ���б�Ƕ���б��������
    ConvertListsInBodyToHtml oDoc
    
    ' ������ʽȫ����Ϊ������ʽ
    PreprocessBasicFormat oDoc
    
    ' ���תΪ HTML ��ǩ
    ' Ŀǰֻ֧����ͨ�����к���Ԫ��ϲ��ı��
    ' ��������������Ԫ��ϲ��ı��
    ConvertTablesToHtml oDoc
    
    ' �����ĵ������е�ͼƬ
    SaveImagesToDiskFiles oDoc
    
    ProcessQuestionBody oDoc   ' �������
    ProcessQuestionOption oDoc ' ����ѡ��
    ProcessAnswer oDoc         ' �����
    PrepareQuestionAttr oDoc   ' ������Ŀ�����ֶΣ��ѷ��ࡢ��š����͵���Ŀ�ֶ�ת�ɴ�����ĸ�ʽ
    
    ' ���ѹأ�����������ʽ
    PostprocessDocumentFormat oDoc

    oDoc.Save

    Application.ScreenUpdating = True

    ' ���Ϊ txt
    SaveMeToTxt oDoc
    
    MsgBox "Hah, DONE!"
End Sub

Private Sub PreprocessBasicFormat(oDoc As Document)
' Ԥ�����ʽ
    
    Debug.Print "PreprocessBasicFormat"

    With oDoc.Content.Find
        .ClearFormatting
        .Execute FindText:="^l", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="^13{2,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="^13[  ^9]{1,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="[  ^9]{1,}^13", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="[��\(] {1,}[��\)]", ReplaceWith:="��&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;��", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
    End With
End Sub

Private Sub PostprocessDocumentFormat(oDoc As Document)
' �����һ��������ʽ

    Debug.Print "PostprocessDocumentFormat"

    oDoc.Range.Select
    
    If StyleExists("����", oDoc) = True Then
        Selection.Style = "����"
    ElseIf StyleExists("Normal", oDoc) = True Then
        Selection.Style = "Normal"
    End If
    
    With oDoc.Content.Find
        .ClearFormatting
        .Execute FindText:="</p>^p<", ReplaceWith:="</p><", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<p></p>", ReplaceWith:="", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<p><table", ReplaceWith:="<table", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</table></p>", ReplaceWith:="</table>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="(=category#[!^13]{1,})^13=end", ReplaceWith:="\1", Forward:=True, MatchWildcards:=True
    End With
End Sub

Private Sub PrepareQuestionAttr(oDoc As Document)
' ������Ŀ�ֶ�

    Debug.Print "PrepareQuestionAttr"
    
    With oDoc.Content.Find
        .ClearFormatting
        .Execute FindText:="�����ࡿ", ReplaceWith:="=category#", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="����š�", ReplaceWith:="^p=no#", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����͡���ѡ", ReplaceWith:="^p=type#single_choice", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����͡���ѡ", ReplaceWith:="^p=type#multiple_choice", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����͡��ʴ�", ReplaceWith:="^p=type#subjective_question", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="���Ѷȡ�����", ReplaceWith:="^p=level#3", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="���Ѷȡ����", ReplaceWith:="^p=level#2", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="���Ѷȡ���", ReplaceWith:="^p=level#1", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����⡿��", ReplaceWith:="^p=special#T", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�����⡿", ReplaceWith:="^p=special#", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�������ʽ������", ReplaceWith:="^p=format#grid", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="�������ʽ�����", ReplaceWith:="^p=format#table", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="^13{2,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
    End With
End Sub

Private Sub ConvertTablesToHtml(oDoc As Document)
' �ѱ��תΪ HTML ����ǰ��Ԥ����
    
    Debug.Print "ConvertTablesToHtml"

    Dim oTable As Table
    Dim i As Integer
    
    ' ���ǰ��ӿ���
    For i = oDoc.Tables.Count To 1 Step -1
        oDoc.Tables(i).Range.Select
        With Selection
            .Cut
            .Text = vbCrLf & vbCrLf & vbCrLf
            .End = .End - 1
            .start = .start + 1
            .Paste
        End With
    Next
    
    IterateTables oDoc
    
End Sub

Private Sub IterateTables(oDoc As Document)
' �ѱ��תΪ HTML

    Debug.Print "IterateTables"

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
    For i = oDoc.Tables.Count To 1 Step -1
        Set objTable = oDoc.Tables(i)
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

Private Sub ConvertListsInOptionsToText(oDoc As Document)
' ѡ���е���Ŀ���ת������
' �Ȱ�ѡ���е���Ŀ��Ŵ���������� ConvertListsInQuestionBodyToHtml ��������е���Ŀ���

    Debug.Print "ConvertListsInOptionsToText"

    Dim oPara As Paragraph
    
    With oDoc.Content.Find
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

Private Sub ConvertQuestionNoListsToText(oDoc As Document)
' ��ŵ���Ŀ���ת�ı�

    Debug.Print "ConvertQuestionNoListsToText"

    Dim oPara As Paragraph
    
    For Each oPara In oDoc.listParagraphs
        If StartsWith(oPara.Range.ListFormat.ListString, "����š�") = True Then
            oPara.Range.ListFormat.ConvertNumbersToText
        End If
    Next oPara
    
    With oDoc.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="����š�", ReplaceWith:="=end^p����š�", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
    End With
    
    oDoc.Content.Select
    Selection.InsertAfter vbCrLf & "=end"
End Sub

Private Sub ConvertListsInBodyToHtml(oDoc As Document)
' ��ɡ��𰸻��������Ŀ���ת�� HTML

    Debug.Print "ConvertListsInBodyToHtml"

    Dim oList As List
    Dim oPara As Paragraph
    
    For Each oList In oDoc.Lists
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
        
        If StyleExists("����", oDoc) = True Then
            strStyleName = "����"
        ElseIf StyleExists("Normal", oDoc) = True Then
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
    With oDoc.Content.Find
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

Private Sub ProcessQuestionBody(oDoc As Document)
' �������
    
    Debug.Print "ProcessQuestionBody"
    
    Dim oRange As Range
    Dim oPara As Paragraph
    Dim strBody As String
    Dim strPara As String
    
    ' ����ɡ� ��������
    With oDoc.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="����ɡ�", ReplaceWith:="����ɡ�^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
    
    ' ��������ɡ��͡� ֮��Ĳ���
    Set oRange = oDoc.Range
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
    With oDoc.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="<p><ol", ReplaceWith:="<ol", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ol></p>", ReplaceWith:="</ol>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<p><ul>", ReplaceWith:="<ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ul></p>", ReplaceWith:="</ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="����ɡ�^p", ReplaceWith:="=body#", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
End Sub

Private Sub ProcessAnswer(oDoc As Document)
' ��������۵Ĵ�
    
    Debug.Print "ProcessAnswer"
    
    Dim oRange As Range
    Dim oPara As Paragraph
    Dim strBody As String
    Dim strPara As String
    
    ' ���𰸡� ��������
    With oDoc.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="���𰸡�", ReplaceWith:="���𰸡�^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
        ' ������ֿ��и��Ŵ�������
        .Execute FindText:="^13{2,}", ReplaceWith:="^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
    
    ' �������𰸡��͡� ֮��Ĳ���
    Set oRange = oDoc.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="���𰸡�*��", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            oRange.MoveStart Unit:=wdCharacter, Count:=5
            oRange.MoveEnd Unit:=wdCharacter, Count:=-1
            'Debug.Print oRange.Text
            oRange.Select
            
            If Len(Replace(Replace(Selection.Text, vbCrLf, ""), vbCr, "")) > 1 Then ' ��������С��𰸡���ǵ������ݵ����
                strBody = ""
                For Each oPara In Selection.Range.Paragraphs
                    strPara = oPara.Range.Text
                    strPara = Replace(strPara, vbCrLf, "")
                    strPara = Replace(strPara, vbCr, "")
                    
                    If Len(strPara) Then
                        strBody = strBody & "<p>" & strPara & "</p>"
                    End If
                Next oPara
                'Debug.Print strBody
                
                If Len(Selection) And Selection.Text <> "" Then
                    Selection.Cut
                    Selection.InsertBefore strBody & vbCrLf
                End If
            End If
            
            .Execute
        Loop
    End With
    
    ' �޳������ <p></p> ��ǩ
    With oDoc.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="<p><ol", ReplaceWith:="<ol", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ol></p>", ReplaceWith:="</ol>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="<p><ul>", ReplaceWith:="<ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="</ul></p>", ReplaceWith:="</ul>", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="���𰸡�^p", ReplaceWith:="^p=answer#", Forward:=True, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
End Sub

Private Sub ProcessQuestionOption(oDoc As Document)
' ����ѡ��

    Debug.Print "ProcessQuestionOption"
    
    Dim oRange As Range
    Dim i As Integer
    Dim strOptions As String
    Dim strOptionAnswer As String
    
    ' ����ѡ��
    With oDoc.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="^13([A-Z])[.�� ^9]{1,}", ReplaceWith:="^p\1#", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
    
    ' ����ѡ������
    Set oRange = oDoc.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="��ѡ�*���𰸡�[A-Z]{1,}^13", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            strOptions = oRange.Text
            oRange.Select
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
    With oDoc.Range.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="^13[A-Z]#", ReplaceWith:="^p=option#", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
        .Execute FindText:="��ѡ�^p", ReplaceWith:="", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="^13���𰸡�[A-D]{1,}^13", ReplaceWith:="^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
End Sub

Private Sub ConvertSuperscriptToHtml(oDoc As Document)
' ���ϱ�תΪ <sup></sup>

    Debug.Print "ConvertSuperscriptToHtml"

    oDoc.Select
   
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

Private Sub ConvertSubscriptToHtml(oDoc As Document)
' ���±�תΪ <sub></sub>

    Debug.Print "ConvertSubscriptToHtml"

    oDoc.Select
   
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

Private Sub SaveImagesToDiskFiles(oDoc As Document)
' ��ͼƬ���Ϊ�ļ�
' �����ı�ͼƬ�滻Ϊ���� [img]201809121523_001.jpg[/img] �� BBCode ��ʽ

    Debug.Print "SaveImagesToDiskFiles"

    ' Shape ����תΪ InlineShape
    Dim objShape As Shape
    For Each objShape In oDoc.Shapes
        objShape.ConvertToInlineShape
    Next objShape
    
    Dim objInlineShape As InlineShape
    Dim byteData() As Byte
    Dim i As Long
    Dim intWritePos As Long
    Dim strOutFilePath As String
    Dim strPictureFileName As String
    Dim strDateTime As String
    Dim intWidth As Integer
    Dim intHeight As Integer
    Dim intRealWidth As Integer
    Dim intRealHeight As Integer
    Dim strShapeName As String
    
    ' ��ǰʱ�� ������ʱ��
    strDateTime = Format(Now(), "YYYYMMDDHHmm_")
    
    ' =======================���ӵĶ���Ҫ������======================
    
    ' �½� Excel�����ڵ����ĵ��е�ͼƬ
    Dim xlExcelApp As Excel.Application
    Dim xlWorkBook As Excel.Workbook
    Dim xlWorkSheet As Excel.WorkSheet
    Dim xlChart As Excel.Chart
    Dim xlChartObject As Excel.ChartObject
    Set xlExcelApp = CreateObject("Excel.Application")
    Set xlWorkBook = xlExcelApp.Workbooks.Add
    Set xlWorkSheet = xlWorkBook.Worksheets(1)
    xlExcelApp.Visible = True
    
    For i = oDoc.InlineShapes.Count To 1 Step -1
        Set objInlineShape = oDoc.InlineShapes(i)
        ' �ĵ��е�ͼƬ�ߴ�
        intWidth = Round(objInlineShape.Width / 72 * 96)
        intHeight = Round(objInlineShape.Height / 72 * 96)
        
        ' ����ͼƬ��Сʱ�ĳߴ磬���ڵ���
        objInlineShape.ScaleWidth = 100
        objInlineShape.ScaleHeight = 100
        intRealWidth = objInlineShape.Width
        intRealHeight = objInlineShape.Height

        ' ����Ҫ������ͼ
        objInlineShape.Select
        Selection.CopyAsPicture
        
        strPictureFileName = strDateTime & PadNumber(CStr(i), 2)
        strOutFilePath = oDoc.Path & Application.PathSeparator & strPictureFileName & ".jpg"
        
        ' �� Excel �е���ͼƬ�ļ�
        With xlExcelApp
            ' ����ͼ��
            .Charts.Add
            .ActiveChart.Location Where:=xlLocationAsObject, Name:="Sheet1"
            .Selection.Border.LineStyle = 0
            strShapeName = .Selection.Name & " " & Split(.ActiveChart.Name, " ")(2)
            
            .ActiveSheet.Shapes(strShapeName).Width = intRealWidth
            .ActiveSheet.Shapes(strShapeName).Height = intRealHeight
            
            ' �ѿ�����ͼճ��ͼ��������
            .ActiveChart.ChartArea.Select
            .ActiveChart.Paste
            
            ' ����ͼƬ
            .ActiveSheet.ChartObjects(1).Chart.Export FileName:=strOutFilePath, filtername:="jpg"
            
            .ActiveSheet.Shapes(strShapeName).Delete
        End With
        
        ' �滻�ļ���ͼƬ
        Selection.Cut
        Selection.InsertBefore "[img=" & CStr(intWidth) & "," & CStr(intHeight) & "]" _
            & strPictureFileName & ".jpg[/img]" & vbCrLf
    Next i
    
    xlWorkBook.Close savechanges:=False
    
    With oDoc.Content.Find
        .ClearFormatting
        .Execute FindText:="^13{2,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
    End With
End Sub

Private Sub SaveMeToTxt(oDoc As Document)
' ������ı��ļ�

    Debug.Print "SaveMeToTxt"
    
    Dim strFilePath As String
    strFilePath = oDoc.Path & Application.PathSeparator & oDoc.Name
    strFilePath = Mid(strFilePath, 1, InStrRev(strFilePath, ".") - 1)
    
    oDoc.SaveAs2 FileName:=strFilePath, FileFormat:= _
        wdFormatText, LockComments:=False, Password:="", AddToRecentFiles:=False, _
        WritePassword:="", ReadOnlyRecommended:=False, EmbedTrueTypeFonts:=False, _
         SaveNativePictureFormat:=False, SaveFormsData:=False, SaveAsAOCELetter:= _
        False, Encoding:=65001, InsertLineBreaks:=False, AllowSubstitutions:= _
        False, LineEnding:=wdLFOnly, CompatibilityMode:=0
    oDoc.Close
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
    
    StyleExists = False
    
    For Each objStyle In doc.Styles
        If objStyle.NameLocal = strStyleName Then
            StyleExists = True
            Exit For
        End If
    Next objStyle
End Function

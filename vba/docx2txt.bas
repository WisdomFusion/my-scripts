Attribute VB_Name = "ģ��1"
Option Explicit
Option Base 1

Sub Docx2Txt()
    ' main ����������ǰ�ĵ�
    ' ע�⣺
    ' 1. ���ĵ�Ϊ docm ���ú�� Word �ĵ������ڳ��δ�ʱ���ú�
    ' 2. ���ĵ����� body ������ʽ���ڸ�ʽ���ĵ�������ɾ�����綪ʧ�ɻ���������ʽ���һ����Ϊ body ����ʽ
    ' 3. �Ѵ�������ļ�����ճ�������ĵ���ճ��ѡ��ѡ�񡰺ϲ���ʽ��
    ' 4. ���ĵ��к���ͼƬ�����ڱ��ĵ�ͬĿ¼������ .emf �м��ʽͼƬ�ļ���Ϊ������ң��ɽ����ĵ��������½��Ŀհ��ļ�����
    
    ' ������ʽȫ����Ϊ body ��ʽ
    PreprocessDocumentFormat
    
    ' ��Ҫ�ĸ�ʽתΪ HTML ��ǩ
    ConvertSuperscriptToHtml
    ConvertSubscriptToHtml
    
    ' ѡ������Ŀ���תΪ�ı�
    ' ע�⣺���Ҫ������ɻ���������Ŀ��Ŵ����
    ConvertListsInOptionsToText
    
    ' ��ɺʹ��е��б�תΪ ol,ul �� HTML ��ǩ
    ' Ŀǰֻ֧��һ���б�Ƕ���б��������
    ConvertListsInBodyToHtml
    
    ' ���תΪ HTML ��ǩ
    ' Ŀǰֻ֧����ͨ�����к���Ԫ��ϲ��ı��
    ' ��������������Ԫ��ϲ��ı��
    ConvertTablesToHtml
    
    ' �����ĵ������е�ͼƬ
    ' ���� emf ��ʽ�ļ�����תΪ jpg
    SaveImagesToDiskFiles
    
    ' ������Ŀ�����ֶ�
    ' �ѷ��ࡢ��š����͵���Ŀ�ֶ�ת�ɴ�����ĸ�ʽ
    PrepareQuestionAttr

    ' ���Ϊ txt
    SaveMeToTxt
End Sub

Private Sub PreprocessDocumentFormat()
    ' Ԥ�����ʽ
    ActiveDocument.Select
    
    With Selection.Find
        .ClearFormatting
        .Execute FindText:="^l", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=False, Replace:=wdReplaceAll
        .Execute FindText:="^13{2,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="^13[ ��^9]{1,}", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
        .Execute FindText:="[ ��^9]{1,}^13", ReplaceWith:="^p", Forward:=True, Format:=False, MatchWildcards:=True, Replace:=wdReplaceAll
    End With
End Sub

Private Sub PrepareQuestionAttr()
    ActiveDocument.Select
    
    With Selection.Find
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

Private Sub ConvertTablesToHtml()
    ' �ѱ��תΪ HTML ����
    Dim oTable As Table
    Dim i As Integer
    
    ' ���ǰ��ӿ���
    For i = ActiveDocument.Tables.Count To 1 Step -1
        ActiveDocument.Tables(i).Range.Select
        With Selection
            .Cut
            .Text = vbCrLf & vbCrLf & vbCrLf
            .End = .End - 1
            .start = .start + 1
            .Paste
        End With
    Next
    
    IterateTables
    
End Sub

Private Sub IterateTables()
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
    For i = ActiveDocument.Tables.Count To 1 Step -1
        Set objTable = ActiveDocument.Tables(i)
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

Private Sub ConvertListsInOptionsToText()
    ' ѡ���е���Ŀ���ת������
    ' �Ȱ�ѡ���е���Ŀ��Ŵ���������� ConvertListsInQuestionBodyToHtml ��������е���Ŀ���
    Dim lp As Paragraph
    
    ActiveDocument.Select
    
    With Selection.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="��ѡ�*���𰸡�", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            For Each lp In Selection.Range.listParagraphs
                lp.Range.ListFormat.ConvertNumbersToText
            Next lp
            
            .Execute
        Loop
    End With
End Sub

Private Sub ConvertListsInBodyToHtml()
    ' ��ɡ��𰸻��������Ŀ���ת�� HTML
    Dim oList As List
    Dim oPara As Paragraph
    
    For Each oList In ActiveDocument.Lists
        With oList.Range
            .MoveStart unit:=wdCharacter, Count:=-1
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
        
        ' �б������˼� <li></li> ��ǩ
        For Each oPara In oList.listParagraphs
    
            With oPara.Range
                .Style = "body" ' ����ͬ����Ҫ������ʽ body
                .Text = "<li>" & .Text & "</li>"
            End With
        Next
    Next
    
    ' ����������е� </li> ��ǩ
    With ActiveDocument.Content.Find
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

Private Sub ProcessQuestionBody()
    Dim oRange As Range
    Dim oPara As Paragraph
    
    With ActiveDocument.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="����ɡ�", ReplaceWith:="����ɡ�^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
    End With
    
    Set oRange = ActiveDocument.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="����ɡ�*��ѡ�", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            For Each oPara In oRange.Paragraphs
                oPara.Range.Text = "<p>" & oPara.Range.Text & "</p>"
            Next oPara
            
            .Execute
        Loop
    End With
End Sub

Private Sub ProcessQuestionOption()
    Dim oRange As Range
    Dim i As Integer
    Dim strOptions As String
    Dim strOptionAnswer As String
    
    ' ����ѡ��
    With ActiveDocument.Content.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="^13([A-Z])[.�� ]^9", ReplaceWith:="^p\1#", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
    
    ' ����ѡ������
    Set oRange = ActiveDocument.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="��ѡ�*���𰸡�[A-Z]{1,}^13", Forward:=True, Format:=False, MatchWildcards:=True
        
        Do While .Found = True
            strOptions = oRange.Text
            Debug.Print strOptions
            
            strOptionAnswer = Mid(oRange.Text, InStr(1, oRange.Text, "���𰸡�") + 4)
            strOptionAnswer = Replace(strOptionAnswer, vbCrLf, "")
            strOptionAnswer = Replace(strOptionAnswer, vbCr, "")
            Debug.Print strOptionAnswer
            
            ' �����ȷѡ��ı��
            For i = 1 To Len(strOptionAnswer)
                strOptions = Replace(strOptions, Mid(strOptionAnswer, i, 1) & "#", Mid(strOptionAnswer, i, 1) & "#T#")
            Next
            
            Debug.Print strOptions
            
            ' �滻���ĵ���
            oRange.Cut
            oRange.InsertBefore strOptions
            
            .Execute
        Loop
    End With
    
    ' ��ѡ���滻�� =option# ��ͷ�ĸ�ʽ
    ' �޳���ѡ���
    ' �޳�ѡ����ġ��𰸡���
    Set oRange = ActiveDocument.Range
    With oRange.Find
        .ClearFormatting
        .Replacement.ClearFormatting
        .Execute FindText:="^13[A-Z]#", ReplaceWith:="^p=option#", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
        .Execute FindText:="��ѡ�^p", ReplaceWith:="", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=False
        .Execute FindText:="^13���𰸡�[A-D]{1,}^13", ReplaceWith:="^p", Forward:=True, Format:=False, Replace:=wdReplaceAll, MatchWildcards:=True
    End With
End Sub

Private Sub ConvertSuperscriptToHtml()
    ' ���ϱ�תΪ <sup></sup>

    ActiveDocument.Select
   
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

Private Sub ConvertSubscriptToHtml()
    ' ���±�תΪ <sub></sub>

    ActiveDocument.Select
   
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

Private Sub SaveImagesToDiskFiles()
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
    
    For i = ActiveDocument.InlineShapes.Count To 1 Step -1
        Set objShape = ActiveDocument.InlineShapes(i)
        objShape.Select
        
        strPictureFileName = strDateTime & PadNumber(CStr(i), 2)
        ' �ȴ�� emf������ check �����ļ�ʱ��תΪ jpg
        strOutFilePath = ActiveDocument.Path & Application.PathSeparator & strPictureFileName & ".emf"
        
        ' �����ļ�
        Open strOutFilePath For Binary Access Write As #1
        byteData = objShape.Range.EnhMetaFileBits
        intWritePos = 1
        Put #1, intWritePos, byteData
        Close #1
        
        ' �滻�ļ���ͼƬ
        Selection.Cut
        Selection.InsertBefore "[img]" & strPictureFileName & ".emf[/img]"
    Next i
End Sub

Private Sub SaveMeToTxt()
    ' ������ı��ļ�
    Dim strFileName As String
    Dim strFilePath As String
    
    strFileName = ActiveDocument.Name
    strFilePath = ActiveDocument.Path & Application.PathSeparator & strFileName
    
    ActiveDocument.SaveAs2 FileName:=strFilePath, FileFormat:= _
        wdFormatText, LockComments:=False, Password:="", AddToRecentFiles:=True, _
        WritePassword:="", ReadOnlyRecommended:=False, EmbedTrueTypeFonts:=False, _
         SaveNativePictureFormat:=False, SaveFormsData:=False, SaveAsAOCELetter:= _
        False, Encoding:=936, InsertLineBreaks:=False, AllowSubstitutions:=False, _
         LineEnding:=wdCRLF, CompatibilityMode:=0
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

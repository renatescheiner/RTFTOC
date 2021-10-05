/**
\file      RTFTOC.sas
\ingroup   HLP_DEV
\brief     prepare for table of contents in RTF Output
\details   This macro adds RTF Tags to the stylesheet in RTF code.
           Up to 2 lines for chapter titles are possible. 
           The formats to be adressed in RTF are:
              ChapterTitle
              ChapterSubTitle
           Up to 2 chapter titles and up to 3 table titles can be addressed.
           For tables covering more than 1 page, only the first group of titles are formatted.
           The formats to be adressed in RTF are:
              TableTitle
              TableSubTitle
              TableSubSubTitle

\author    Renate Scheiner-Sparna
\since     2020-02-10 
\date      YYYY-MM-DD Date of finalisation of current version
\version   SAS 9.4/1.0 SAS-Version / Programm version

\param     filename - Mandatory. SAS filename for RTF file
           DevFL    - Optional. Development flag, set to Y to keep temporary datasets. 
\return       
    <br>

    \b Example <br>
       \code
          %RTFTOC(&gFileTables., DevFL=Y)
       \endcode

    \b Verification 
       - Verified on: <br> 
       - Verified by: <br> 
       - Validation model: <br>

   <b> Change History </b>
      - Changed on: <br>
      - Changed by: <br>
      - Reason for change: <br>
      - Change verified on: <br>
      - Change verified by: <br>
*/
/** \cond */


%macro RTFTOC(filename, DevFL=);

%* create format element to be added to RTF file (does not work inside the macro!);
%let styles=%nrquote(
"{\s2 TableTitle;}{\s3 TableSubTitle;}{\s4 TableSubSubTitle;}{\s10 ChapterTitle;}{\s11 ChapterSubTitle;}"
); 

%GM_CreateRandomString_v1(1, rtftoc)

%* read rtf file in dataset;
%* keep _n_ as lineno;
data &rtftoc1._rtf;
  infile &filename. length = LineLength end=eof;
  input Line $varying1000. LineLength;
  LineNo = _n_;
run;

data &rtftoc1._rtf1;
  set &rtftoc1._rtf;
  by LineNo;
  %* create groups of lines by table/figure;
  %* caution: first lines are without object, because the title statement is later than the the 
    corresponding 'Normal' tag;
  retain object_s2 object_s3 object_s4;
  length object_s2 object_s3 object_s4 $1000;
  if index(line, "{\s2 ") then do;
    object_s2=line;
    object_s3='';
    object_s4='';
  end;
  if index(line, "{\s3 ") then do;
    object_s3=line;
    object_s4='';
  end;
  if index(line, "{\s4 ") then object_s4=line;
run;

proc sort data=&rtftoc1._rtf1 out=&rtftoc1._rtf1_sort;
  by object_s2 object_s3 object_s4;
run;

%* for tables covering more than 1 page: change \s2 \s3 \s4 to \s99 on later pages;
data &rtftoc1._rtf2;
  set &rtftoc1._rtf1_sort;
  by object_s2 object_s3 object_s4;
  if index(line, "{\s2 ") and not(first.object_s2) 
    then line=tranwrd(line, "{\s2 ", "{\s99 ");
  if index(line, "{\s3 ") and not(first.object_s3) 
    then line=tranwrd(line, "{\s3 ", "{\s99 ");
  if index(line, "{\s4 ") and not(first.object_s4) 
    then line=tranwrd(line, "{\s4 ", "{\s99 ");
run;

proc sort data=&rtftoc1._rtf2 out=&rtftoc1._rtf2_sort;
  by LineNo;
run;

data _null_;
  set &rtftoc1._rtf2_sort (keep=line);
  %* read only non-missing entries in order to avoid problems with leading blanks in footnotes;
  if line ne "";
  file &filename. lrecl = 1000; 

  if index(line,"Normal;}")>0 then do;
    temp = cats(line, &styles.);
    put temp;
  end;
  else put line;
run;

%if %upcase(&DevFL.) ne Y %then %do;

  proc datasets lib=work memtype=data nolist;
       delete &rtftoc1.: ;  
  quit;  
  %symdel rtftoc1;

%end;

%mend RTFTOC;

 

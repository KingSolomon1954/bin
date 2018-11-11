ProgressOn("Progress Meter", "", "")

$max = 100000
For $count = 1 To $max
    WinWaitActive("Contact - Microsoft Internet Explorer")
    Sleep(250)
    Send("{ENTER}")
    ProgressSet((100 * $count) / $max, $count & " out of " & $max)
    WinWaitActive("Form Submission Confirmation - Microsoft Internet Explorer")
    Sleep(250)
    Send("{BS}")
Next

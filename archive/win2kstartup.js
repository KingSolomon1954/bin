// -------------------------------------------------------
//
// Perform some actions at login.
// 
//     1. Deletes annoying directories that keep coming back.
//
// Run with:
//
//     cscript win2kstartup.js //Nologo 
//
// -------------------------------------------------------

var debug = true;

// -------------------------------------------------------

function main()
{
    var fso;
    fso = new ActiveXObject("Scripting.FileSystemObject");
    
    deleteFolder(fso, "c:/home/howie/My Music");
    deleteFolder(fso, "c:/home/howie/My eBooks");
    deleteFolder(fso, "c:/home/howie/My Pictures");
    deleteFolder(fso, "c:/home/howie/My Games");
}

// -------------------------------------------------------

function out(s)
{
    if (debug)
    {
        // WScript.StdOut.Write(s);
        WScript.Echo(s);
    }
}

// -------------------------------------------------------

function deleteFolder(fso, folderName)
{
    if (fso.FolderExists(folderName))
    {
        out("Deleting folder: " + folderName);
        fso.DeleteFolder(folderName);
    }
    else
    {
        out("Skipping non-existent folder: " + folderName);
    }
}

// -------------------------------------------------------

main()

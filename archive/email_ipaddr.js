// -------------------------------------------------------
//
// email_ipaddr
// 
//     Obtains default gateway IP address and emails it
//     to my work.
//
// Run with:
//
//     cscript email_ipaddr.js //Nologo 
//
// -------------------------------------------------------

var debug = true;

// -------------------------------------------------------

function main()
{
    sendmail(getIpAddress());
}

// -------------------------------------------------------

function sendmail(ipAddr)
{
    var objEmail;
    objEmail = new ActiveXObject("CDO.Message");
    
    objEmail.From     = "hsolomon@san.rr.com";
    objEmail.To       = "howie.solomon@viasat.com";
    objEmail.Subject  = "IP Address" 
    objEmail.Textbody = "ssh -l howie " + ipAddr;
    objEmail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2;
    objEmail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserver") = "smtpserver.san.rr.com" ;
    objEmail.Configuration.Fields.Item("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = 25;
    objEmail.Configuration.Fields.Update();
    objEmail.Send();
}

// -------------------------------------------------------

function getIpAddress()
{
    var wbemFlagReturnImmediately = 0x10;
    var wbemFlagForwardOnly = 0x20;

    var objWMIService = GetObject("winmgmts:\\\\.\\root\\CIMV2");
    var colItems = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration", "WQL",
                                          wbemFlagReturnImmediately | wbemFlagForwardOnly);

    var enumItems = new Enumerator(colItems);
    for (; !enumItems.atEnd(); enumItems.moveNext())
    {
        var objItem = enumItems.item();

        try
        { 
            addr = (objItem.DefaultIPGateway.toArray()).join(",");
            return addr;
        }
        catch(e)
        {
        }

        // try
        // {
        //     WScript.Echo("IP Address: " + (objItem.IPAddress.toArray()).join(","));
        // }
        // catch(e)
        // {
        //     WScript.Echo("IP Address: null");
        // }
    }
    return "No default gateway";
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

main()

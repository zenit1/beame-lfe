//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated from a template.
//
//     Manual changes to this file may cause unexpected behavior in your application.
//     Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace LFE.Model
{
    using System;
    using System.Collections.Generic;
    
    public partial class LogTable
    {
        public long id { get; set; }
        public string Origin { get; set; }
        public string LogLevel { get; set; }
        public string Message { get; set; }
        public string Exception { get; set; }
        public string StackTrace { get; set; }
        public string Logger { get; set; }
        public Nullable<System.Guid> RecordGuidId { get; set; }
        public Nullable<int> RecordIntId { get; set; }
        public System.DateTime CreateDate { get; set; }
        public string RecordObjectType { get; set; }
        public string IPAddress { get; set; }
        public string HostName { get; set; }
        public Nullable<int> UserId { get; set; }
        public string SessionId { get; set; }
    }
}

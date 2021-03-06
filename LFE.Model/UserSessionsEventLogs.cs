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
    
    public partial class UserSessionsEventLogs
    {
        public long EventID { get; set; }
        public long SessionId { get; set; }
        public short EventTypeID { get; set; }
        public System.DateTime EventDate { get; set; }
        public string AdditionalData { get; set; }
        public string salesforce_id { get; set; }
        public string salesforce_checksum { get; set; }
        public Nullable<int> WebStoreId { get; set; }
        public string AubsoluteUri { get; set; }
        public Nullable<int> CourseId { get; set; }
        public Nullable<int> BundleId { get; set; }
        public bool ExportToFact { get; set; }
        public Nullable<long> VideoBcIdentifier { get; set; }
        public string HostName { get; set; }
    
        public virtual UserSessions UserSessions { get; set; }
        public virtual WebStores WebStores { get; set; }
        public virtual CRS_Bundles CRS_Bundles { get; set; }
        public virtual Courses Courses { get; set; }
    }
}

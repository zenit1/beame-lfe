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
    
    public partial class WS_StoreListToken
    {
        public int StoreID { get; set; }
        public System.Guid uid { get; set; }
        public string StoreName { get; set; }
        public System.DateTime AddOn { get; set; }
        public short StatusId { get; set; }
        public string StatusName { get; set; }
        public Nullable<int> C_Courses { get; set; }
        public int C_Subscribers { get; set; }
        public string TrackingID { get; set; }
        public int OwnerUserID { get; set; }
        public string Nickname { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string WixSiteUrl { get; set; }
        public Nullable<short> DefaultCurrencyId { get; set; }
    }
}

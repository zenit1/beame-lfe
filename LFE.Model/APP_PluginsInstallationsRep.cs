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
    
    public partial class APP_PluginsInstallationsRep
    {
        public int InstallationId { get; set; }
        public byte TypeId { get; set; }
        public string UId { get; set; }
        public string Domain { get; set; }
        public Nullable<decimal> Version { get; set; }
        public Nullable<int> UserId { get; set; }
        public bool IsActive { get; set; }
        public System.DateTime AddOn { get; set; }
        public Nullable<System.DateTime> UpdateDate { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Email { get; set; }
        public string Nickname { get; set; }
        public Nullable<System.DateTime> UserAddOn { get; set; }
    }
}

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
    
    public partial class PO_PayoutExecutions
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public PO_PayoutExecutions()
        {
            this.PO_UserPayoutStatments = new HashSet<PO_UserPayoutStatments>();
        }
    
        public int ExecutionId { get; set; }
        public int PayoutYear { get; set; }
        public int PayoutMonth { get; set; }
        public byte StatusId { get; set; }
        public System.DateTime AddOn { get; set; }
        public Nullable<int> CreatedBy { get; set; }
        public Nullable<System.DateTime> UpdateOn { get; set; }
        public Nullable<int> UpdatedBy { get; set; }
    
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<PO_UserPayoutStatments> PO_UserPayoutStatments { get; set; }
    }
}

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
    
    public partial class BILL_ItemsPriceRevisions
    {
        public int RevisionId { get; set; }
        public int PriceLineId { get; set; }
        public decimal Price { get; set; }
        public System.DateTime FromDate { get; set; }
        public Nullable<System.DateTime> ToDate { get; set; }
        public Nullable<int> CreatedBy { get; set; }
        public Nullable<int> UpdatedBy { get; set; }
        public bool IsDeleted { get; set; }
    
        public virtual BILL_ItemsPriceList BILL_ItemsPriceList { get; set; }
    }
}

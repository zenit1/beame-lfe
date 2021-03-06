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
    
    public partial class BILL_ItemsPriceList
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public BILL_ItemsPriceList()
        {
            this.BILL_ItemsPriceRevisions = new HashSet<BILL_ItemsPriceRevisions>();
            this.SALE_OrderLines = new HashSet<SALE_OrderLines>();
        }
    
        public int PriceLineId { get; set; }
        public int ItemId { get; set; }
        public byte ItemTypeId { get; set; }
        public byte PriceTypeId { get; set; }
        public Nullable<byte> PeriodTypeId { get; set; }
        public short CurrencyId { get; set; }
        public decimal Price { get; set; }
        public string Name { get; set; }
        public Nullable<byte> NumOfPeriodUnits { get; set; }
        public bool IsDeleted { get; set; }
        public System.DateTime AddOn { get; set; }
        public Nullable<int> CreatedBy { get; set; }
        public Nullable<System.DateTime> UpdateOn { get; set; }
        public Nullable<int> UpdatedBy { get; set; }
    
        public virtual BASE_CurrencyLib BASE_CurrencyLib { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<BILL_ItemsPriceRevisions> BILL_ItemsPriceRevisions { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<SALE_OrderLines> SALE_OrderLines { get; set; }
    }
}

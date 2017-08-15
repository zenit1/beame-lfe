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
    
    public partial class SALE_Orders
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public SALE_Orders()
        {
            this.SALE_OrderLines = new HashSet<SALE_OrderLines>();
        }
    
        public System.Guid OrderId { get; set; }
        public int Sid { get; set; }
        public int BuyerUserId { get; set; }
        public int SellerUserId { get; set; }
        public Nullable<int> WebStoreId { get; set; }
        public byte StatusId { get; set; }
        public System.DateTime OrderDate { get; set; }
        public Nullable<int> AddressId { get; set; }
        public byte PaymentMethodId { get; set; }
        public Nullable<System.Guid> InstrumentId { get; set; }
        public System.DateTime AddOn { get; set; }
        public Nullable<int> CreatedBy { get; set; }
        public Nullable<System.DateTime> UpdateDate { get; set; }
        public Nullable<int> UpdatedBy { get; set; }
        public Nullable<System.DateTime> CancelledOn { get; set; }
    
        public virtual USER_Addresses USER_Addresses { get; set; }
        public virtual USER_PaymentInstruments USER_PaymentInstruments { get; set; }
        public virtual WebStores WebStores { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<SALE_OrderLines> SALE_OrderLines { get; set; }
        public virtual Users Users { get; set; }
        public virtual Users Users1 { get; set; }
    }
}

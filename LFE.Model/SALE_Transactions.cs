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
    
    public partial class SALE_Transactions
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public SALE_Transactions()
        {
            this.SALE_Transactions1 = new HashSet<SALE_Transactions>();
        }
    
        public int TransactionId { get; set; }
        public byte TransactionTypeId { get; set; }
        public int OrderLineId { get; set; }
        public Nullable<int> PaymentId { get; set; }
        public System.DateTime TransactionDate { get; set; }
        public string ExternalTransactionID { get; set; }
        public decimal Amount { get; set; }
        public decimal Fee { get; set; }
        public string Remarks { get; set; }
        public Nullable<System.Guid> RequestId { get; set; }
        public System.DateTime AddOn { get; set; }
        public Nullable<System.DateTime> UpdateDate { get; set; }
        public Nullable<int> SourceTransactionId { get; set; }
        public Nullable<int> RefundId { get; set; }
    
        public virtual PAYPAL_PaymentRequests PAYPAL_PaymentRequests { get; set; }
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<SALE_Transactions> SALE_Transactions1 { get; set; }
        public virtual SALE_Transactions SALE_Transactions2 { get; set; }
        public virtual SALE_OrderLinePaymentRefunds SALE_OrderLinePaymentRefunds { get; set; }
        public virtual SALE_OrderLines SALE_OrderLines { get; set; }
        public virtual SALE_OrderLinePayments SALE_OrderLinePayments { get; set; }
    }
}

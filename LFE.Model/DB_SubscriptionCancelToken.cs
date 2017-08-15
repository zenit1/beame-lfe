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
    
    public partial class DB_SubscriptionCancelToken
    {
        public string PaymentSource { get; set; }
        public Nullable<System.DateTime> CancelledOn { get; set; }
        public int LineId { get; set; }
        public byte LineTypeId { get; set; }
        public string LineTypeCode { get; set; }
        public string PaypalProfileID { get; set; }
        public string ItemName { get; set; }
        public int OrderNumber { get; set; }
        public int BuyerUserId { get; set; }
        public string BuyerEmail { get; set; }
        public string BuyerNickName { get; set; }
        public string BuyerFirstName { get; set; }
        public string BuyerLastName { get; set; }
        public int SellerUserId { get; set; }
        public string SellerEmail { get; set; }
        public string SellerNickName { get; set; }
        public string SellerFirstName { get; set; }
        public string SellerLastName { get; set; }
        public Nullable<int> WebStoreId { get; set; }
        public string TrackingID { get; set; }
        public string StoreName { get; set; }
        public Nullable<int> StoreOwnerUserId { get; set; }
        public string StoreOwnerEmail { get; set; }
        public string StoreOwnerNickname { get; set; }
        public string StoreOwnerFirstName { get; set; }
        public string StoreOwnerLastName { get; set; }
        public byte OrderStatusId { get; set; }
        public string OrderStatusCode { get; set; }
        public Nullable<int> CourseId { get; set; }
        public Nullable<int> BundleId { get; set; }
        public Nullable<int> CouponInstanceId { get; set; }
        public decimal Price { get; set; }
        public decimal TotalPrice { get; set; }
        public decimal Discount { get; set; }
        public Nullable<double> CouponTypeAmount { get; set; }
        public System.DateTime OrderDate { get; set; }
        public Nullable<short> CurrencyId { get; set; }
        public string ISO { get; set; }
        public string Symbol { get; set; }
        public string CurrencyName { get; set; }
        public Nullable<decimal> AffiliateCommission { get; set; }
        public bool IsUnderRGP { get; set; }
        public decimal TotalAmountPayed { get; set; }
    }
}

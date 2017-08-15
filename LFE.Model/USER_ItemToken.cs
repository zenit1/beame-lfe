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
    
    public partial class USER_ItemToken
    {
        public int ItemId { get; set; }
        public System.Guid Uid { get; set; }
        public int ItemTypeId { get; set; }
        public int AuthorId { get; set; }
        public string AuthorNickname { get; set; }
        public string AuthorFirstName { get; set; }
        public string AuthorLastName { get; set; }
        public string ItemName { get; set; }
        public string UrlName { get; set; }
        public string ImageURL { get; set; }
        public Nullable<decimal> Price { get; set; }
        public Nullable<decimal> MonthlySubscriptionPrice { get; set; }
        public int NumSubscribers { get; set; }
        public int Rating { get; set; }
        public Nullable<bool> IsFreeCourse { get; set; }
        public System.DateTime Created { get; set; }
        public short StatusId { get; set; }
        public int CoursesCnt { get; set; }
        public decimal AffiliateCommission { get; set; }
        public string ItemDescription { get; set; }
    }
}
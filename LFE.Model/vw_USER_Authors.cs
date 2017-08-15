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
    
    public partial class vw_USER_Authors
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Email { get; set; }
        public int bundles { get; set; }
        public int courses { get; set; }
        public int stores { get; set; }
        public Nullable<int> total { get; set; }
        public Nullable<bool> IsAuthor { get; set; }
        public string Nickname { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string ActivationToken { get; set; }
        public Nullable<System.DateTime> ActivationExpiration { get; set; }
        public string FacebookID { get; set; }
        public string FbAccessToken { get; set; }
        public Nullable<System.DateTime> FbAccessTokenExpired { get; set; }
        public string PictureURL { get; set; }
        public Nullable<System.DateTime> BirthDate { get; set; }
        public string PasswordDigest { get; set; }
        public Nullable<int> Gender { get; set; }
        public string BioHtml { get; set; }
        public string AuthorPictureURL { get; set; }
        public bool AutoplayEnabled { get; set; }
        public string salesforce_id { get; set; }
        public string salesforce_checksum { get; set; }
        public bool DisplayActivitiesOnFB { get; set; }
        public bool ReceiveMonthlyNewsletterOnEmail { get; set; }
        public bool DisplayDiscussionFeedDailyOnFB { get; set; }
        public bool ReceiveDiscussionFeedDailyOnEmail { get; set; }
        public bool DisplayCourseNewsWeeklyOnFB { get; set; }
        public bool ReceiveCourseNewsWeeklyOnEmail { get; set; }
        public System.DateTime Created { get; set; }
        public System.DateTime LastModified { get; set; }
        public bool IsConfirmed { get; set; }
        public Nullable<System.DateTime> LastLoginDate { get; set; }
        public string ProviderUserId { get; set; }
        public string Provider { get; set; }
        public byte RegistrationTypeId { get; set; }
        public string RegistrationTypeCode { get; set; }
        public decimal AffiliateCommission { get; set; }
    }
}

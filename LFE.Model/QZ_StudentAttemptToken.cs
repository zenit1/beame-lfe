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
    
    public partial class QZ_StudentAttemptToken
    {
        public System.Guid AttemptId { get; set; }
        public bool IsSuccess { get; set; }
        public Nullable<decimal> Score { get; set; }
        public byte StatusId { get; set; }
        public System.DateTime StartOn { get; set; }
        public Nullable<System.DateTime> FinishedOn { get; set; }
        public Nullable<byte> PassPercent { get; set; }
        public string Title { get; set; }
        public System.Guid QuizId { get; set; }
        public Nullable<short> TimeLimit { get; set; }
        public Nullable<byte> Attempts { get; set; }
        public int UserAttempts { get; set; }
        public Nullable<byte> AvailableAttempts { get; set; }
        public System.Guid StudentQuizId { get; set; }
        public bool IsMandatory { get; set; }
        public bool AttachCertificate { get; set; }
        public Nullable<System.DateTime> RequestSendOn { get; set; }
        public Nullable<System.DateTime> ResponseSendOn { get; set; }
        public int AuthorUserId { get; set; }
        public string AuthorEmail { get; set; }
        public string AuthorNickname { get; set; }
        public string AuthorFirstName { get; set; }
        public string AuthorLastName { get; set; }
    }
}

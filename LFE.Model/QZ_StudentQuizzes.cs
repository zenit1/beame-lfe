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
    
    public partial class QZ_StudentQuizzes
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public QZ_StudentQuizzes()
        {
            this.QZ_StudentQuizAttempts = new HashSet<QZ_StudentQuizAttempts>();
        }
    
        public System.Guid StudentQuizId { get; set; }
        public System.Guid QuizId { get; set; }
        public int UserId { get; set; }
        public bool IsSuccess { get; set; }
        public Nullable<decimal> Score { get; set; }
        public Nullable<System.DateTime> LastAttemptStartDate { get; set; }
        public Nullable<byte> AvailableAttempts { get; set; }
        public System.DateTime AddOn { get; set; }
        public Nullable<int> CreatedBy { get; set; }
        public Nullable<System.DateTime> UpdateDate { get; set; }
        public Nullable<int> UpdatedBy { get; set; }
        public Nullable<System.DateTime> RequestSendOn { get; set; }
        public Nullable<System.DateTime> ResponseSendOn { get; set; }
    
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<QZ_StudentQuizAttempts> QZ_StudentQuizAttempts { get; set; }
        public virtual Users Users { get; set; }
        public virtual QZ_CourseQuizzes QZ_CourseQuizzes { get; set; }
    }
}

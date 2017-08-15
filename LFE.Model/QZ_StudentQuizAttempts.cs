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
    
    public partial class QZ_StudentQuizAttempts
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public QZ_StudentQuizAttempts()
        {
            this.QZ_StudentQuizAnswers = new HashSet<QZ_StudentQuizAnswers>();
        }
    
        public System.Guid AttemptId { get; set; }
        public System.Guid StudentQuizId { get; set; }
        public bool IsSuccess { get; set; }
        public Nullable<decimal> Score { get; set; }
        public byte StatusId { get; set; }
        public System.DateTime StartOn { get; set; }
        public Nullable<System.DateTime> FinishedOn { get; set; }
        public Nullable<System.DateTime> AddOn { get; set; }
        public Nullable<int> CreatedBy { get; set; }
        public Nullable<System.DateTime> UpdateDate { get; set; }
        public Nullable<int> UpdatedBy { get; set; }
        public int CurrentIndex { get; set; }
    
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2227:CollectionPropertiesShouldBeReadOnly")]
        public virtual ICollection<QZ_StudentQuizAnswers> QZ_StudentQuizAnswers { get; set; }
        public virtual QZ_StudentQuizzes QZ_StudentQuizzes { get; set; }
    }
}

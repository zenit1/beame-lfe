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
    
    public partial class USER_CourseWatchState
    {
        public int RowId { get; set; }
        public int UserId { get; set; }
        public int CourseId { get; set; }
        public Nullable<int> LastVideoID { get; set; }
        public Nullable<int> LastChapterID { get; set; }
        public Nullable<System.DateTime> LastViewDate { get; set; }
        public System.DateTime AddOn { get; set; }
        public Nullable<int> CreatedBy { get; set; }
        public Nullable<System.DateTime> UpdateDate { get; set; }
        public Nullable<int> UpdatedBy { get; set; }
    
        public virtual Users Users { get; set; }
        public virtual Courses Courses { get; set; }
    }
}